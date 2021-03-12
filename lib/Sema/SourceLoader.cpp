//===--- SourceLoader.cpp - Import .swift files as modules ----------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
///
/// \file
/// A simple module loader that loads .swift source files.
///
//===----------------------------------------------------------------------===//

#include "swift/Sema/SourceLoader.h"
#include "swift/Subsystems.h"
#include "swift/AST/ASTContext.h"
#include "swift/AST/DiagnosticsSema.h"
#include "swift/AST/Module.h"
#include "swift/AST/SourceFile.h"
#include "swift/Parse/PersistentParserState.h"
#include "swift/Basic/SourceManager.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/SaveAndRestore.h"
#include <system_error>

using namespace swift;

// FIXME: Basically the same as SerializedModuleLoader.
using FileOrError = llvm::ErrorOr<std::unique_ptr<llvm::MemoryBuffer>>;

static FileOrError findModule(ASTContext &ctx, StringRef moduleID,
                              SourceLoc importLoc) {
  llvm::SmallString<128> inputFilename;

  for (auto Path : ctx.SearchPathOpts.ImportSearchPaths) {
    inputFilename = Path;
    llvm::sys::path::append(inputFilename, moduleID);
    inputFilename.append(".swift");
    llvm::ErrorOr<std::unique_ptr<llvm::MemoryBuffer>> FileBufOrErr =
      ctx.SourceMgr.getFileSystem()->getBufferForFile(inputFilename.str());

    // Return if we loaded a file
    if (FileBufOrErr)
      return FileBufOrErr;
    // Or if we get any error other than the file not existing
    auto err = FileBufOrErr.getError();
    if (err != std::errc::no_such_file_or_directory)
      return FileBufOrErr;
  }

  return make_error_code(std::errc::no_such_file_or_directory);
}

void SourceLoader::collectVisibleTopLevelModuleNames(
    SmallVectorImpl<Identifier> &names) const {
  // TODO: Implement?
}

bool SourceLoader::canImportModule(ImportPath::Element ID) {
  // Search the memory buffers to see if we can find this file on disk.
  FileOrError inputFileOrError = findModule(Ctx, ID.Item.str(),
                                            ID.Loc);
  if (!inputFileOrError) {
    auto err = inputFileOrError.getError();
    if (err != std::errc::no_such_file_or_directory) {
      Ctx.Diags.diagnose(ID.Loc, diag::sema_opening_import,
                         ID.Item, err.message());
    }

    return false;
  }
  return true;
}

ModuleDecl *SourceLoader::loadModule(SourceLoc importLoc,
                                     ImportPath::Module path) {
  // FIXME: Swift submodules?
  if (path.size() > 1)
    return nullptr;

  auto moduleID = path[0];

  FileOrError inputFileOrError = findModule(Ctx, moduleID.Item.str(),
                                            moduleID.Loc);
  if (!inputFileOrError) {
    auto err = inputFileOrError.getError();
    if (err != std::errc::no_such_file_or_directory) {
      Ctx.Diags.diagnose(moduleID.Loc, diag::sema_opening_import,
                         moduleID.Item, err.message());
    }

    return nullptr;
  }
  std::unique_ptr<llvm::MemoryBuffer> inputFile =
    std::move(inputFileOrError.get());

  if (dependencyTracker)
    dependencyTracker->addDependency(inputFile->getBufferIdentifier(),
                                     /*isSystem=*/false);

  unsigned bufferID;
  if (auto BufID =
       Ctx.SourceMgr.getIDForBufferIdentifier(inputFile->getBufferIdentifier()))
    bufferID = BufID.getValue();
  else
    bufferID = Ctx.SourceMgr.addNewSourceBuffer(std::move(inputFile));

  ImplicitImportInfo importInfo;
  importInfo.StdlibKind = Ctx.getStdlibModule() ? ImplicitStdlibKind::Stdlib
                                                : ImplicitStdlibKind::None;

  auto *importMod = ModuleDecl::create(moduleID.Item, Ctx, importInfo);
  if (EnableLibraryEvolution)
    importMod->setResilienceStrategy(ResilienceStrategy::Resilient);
  importMod->setIsPrivateFramework(!EnableLibraryEvolution);
  Ctx.addLoadedModule(importMod);

  auto *importFile =
      new (Ctx) SourceFile(*importMod, SourceFileKind::Library, bufferID,
                           SourceFile::getDefaultParsingOptions(Ctx.LangOpts));
  importMod->addFile(*importFile);
  performImportResolution(*importFile);
  importMod->setHasResolvedImports();
  bindExtensions(*importMod);
  return importMod;
}

void SourceLoader::loadExtensions(NominalTypeDecl *nominal,
                                  unsigned previousGeneration) {
  // Type-checking the source automatically loads all extensions; there's
  // nothing to do here.
}
