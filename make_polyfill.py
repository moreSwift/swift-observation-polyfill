#!/usr/bin/env python3

import shutil
import os
from typing import Optional

# This is code is a bit janky, so src has to be a direct subdirectory
src = "swift-perception"
dst = "."

if not os.path.exists(src):
    print(f"Expected swift-perception repository to be checked out at ./{src}")
    exit(1)

def do_replacements(text: str, is_code: bool = False, filename: Optional[str] = None) -> str:
    if is_code:
        text = (
            text
            .replace(
                "@attached(extension, conformances: Perceptible, Observable)",
                "@attached(extension, conformances: ObservationPolyfill.Observable)"
            )
            .replace(
                """extension \\(raw: type.trimmedDescription): \\(raw: qualifiedConformanceName), \\
        Observation.Observable {}""",
                "extension \\(raw: type.trimmedDescription): nonisolated \\(raw: qualifiedConformanceName) {}"
            )
            .replace(
                """extension \\(raw: type.trimmedDescription): nonisolated \\(raw: qualifiedConformanceName), \\
        nonisolated Observation.Observable {}""",
                "extension \\(raw: type.trimmedDescription): \\(raw: qualifiedConformanceName) {}"
            )
            .replace('"Observable"', '"Observation.Observable"')
            .replace("@Observable", "@Observation.Observable")
            .replace("@Perceptible", "@ObservationPolyfill.Observable")
            .replace('"PerceptionIgnored"', '"ObservationPolyfill.PerceptionIgnored"')
            .replace('"PerceptionTracked"', '"ObservationPolyfill.PerceptionTracked"')
            .replace("perceptionRegistrar", "observationPolyfillRegistrar")
            .replace("ObservableObject", "SwiftUI.ObservableObject")
            .replace("ObservationRegistrar", "Observation.ObservationRegistrar")
            .replace("any Observable", "any Observation.Observable")
            .replace(", Observable", ", Observation.Observable")
            .replace(": Observable", ": Observation.Observable")
            .replace("withObservationTracking(", "Observation.withObservationTracking(")
        )

    text = (
        text
        .replace("PerceptionTrack", "ObservationTrack")
        .replace("PerceptionIgnored", "ObservationIgnored")
        .replace("Perception", "ObservationPolyfill")
        .replace("perception", "observation")
        .replace("Perceptible", "Observable")
    )

    if filename == "PerceptionMacrosTests.swift":
        # swift-macro-testing doesn't support macros with qualified module
        # names. I'm leaving these replacements here even though they didn't
        # fix the issue, because I think they were the closest attempt to
        # getting things working. It seems like swift-macro-testing just
        # doesn't support qualified macro names whatsoever?
        text = (
            text
            .replace(
                "ObservableMacro.self",
                '"ObservationPolyfill.Observable": ObservableMacro.self'
            )
            .replace(
                "ObservationTrackedMacro.self",
                '"ObservationPolyfill.ObservationTracked": ObservationTrackedMacro.self'
            )
            .replace(
                "ObservationIgnoredMacro.self",
                '"ObservationPolyfill.ObservationIgnored": ObservationIgnoredMacro.self'
            )
        )

    if is_code:
        # Update ObservableMacro to support namespaced spellings of the
        # ObservationIgnored and ObservationTracked macros. Including SwiftCrossUI
        # as a valid namespace here is a bit of a hack, but it's important for users
        # of SwiftCrossUI who may see ObservationIgnored and ObservationTracked as
        # part of the SwiftCrossUI module.
        text = (
            text
            .replace(
                "property.hasMacroApplication(ObservableMacro.ignoredMacroName)",
                '(property.hasMacroApplication(ObservableMacro.ignoredMacroName) || property.hasMacroApplication("ObservationIgnored") || property.hasMacroApplication("SwiftCrossUI.ObservationIgnored"))'
            )
            .replace(
                "property.hasMacroApplication(ObservableMacro.trackedMacroName)",
                '(property.hasMacroApplication(ObservableMacro.trackedMacroName) || property.hasMacroApplication("ObservationTracked") || property.hasMacroApplication("SwiftCrossUI.ObservationTracked"))'
            )
        )

    if filename == "Extensions.swift":
        # Update hasMacroApplication to support namespaced identifiers (which get
        # parsed as a different token sequence).
        text = (
            text
            .replace(
                "attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == [.identifier(name)]",
                'attr.trimmedDescription == "@\\(name)"'
            )
        )

    return text

for (dir, subdirs, files) in os.walk(src):
    dir = dir + "/"
    if "/.git/" in dir or "/.build/" in dir or "/.swiftpm/" in dir or "/Example/" in dir or "/.github/" in dir or "/.jj/" in dir:
        continue
    dir_path = dir.split("/", maxsplit=1)[1] if "/" in dir else ""
    dst_dir = os.path.join(dst, dir_path)
    dst_dir = do_replacements(dst_dir)

    if not os.path.exists(dst_dir):
        os.mkdir(dst_dir)
    elif dst_dir != "./":
        shutil.rmtree(dst_dir)
        os.mkdir(dst_dir)

    for file in files:
        if file in [".DS_Store", "README.md", ".gitignore", ".git"]:
            continue

        src_file = os.path.join(dir, file)
        dst_file = os.path.join(dst_dir, file)
        dst_file = do_replacements(dst_file)

        with open(src_file, "r") as f:
            contents = f.read()
        contents = do_replacements(contents, is_code=True, filename=file)

        print(dst_file)
        with open(dst_file, "w") as f:
            contents = f.write(contents)
