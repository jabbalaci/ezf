#!/usr/bin/env python3

"""
ezf - easily compile and run Fortran programs

A script to compile and launch a Fortran program.
The program can have several modules.
Modules can be in the current directory and/or in the `src/` subdirectory.
The script tries to compile the source files (the imported modules too)
in the correct order.

It was tested under Linux only with the gfortran compiler.

Author: Laszlo Szathmary (jabba.laci@gmail.com), 2026
GitHub: https://github.com/jabbalaci/ezf

Usage:

$ ezf --help            # help

$ ezf -i main.f90       # info

$ ezf main.f90          # compile and run
"""

import os
import sys
from collections import defaultdict
from pathlib import Path
from pprint import pprint

SOURCE_EXTENSIONS = [".f90", ".F90"]
SRC_DIRS = [".", "src"]  # look for files in these folders, in this order
INTRINSICS = [
    "iso_fortran_env",
    "iso_c_binding",
    "ieee_arithmetic",
    "ieee_exceptions",
]

# fmt: off
Options = {
    "info": False,
    "compile": False,
    "run": False
}
# fmt: on


def is_intrinsic(name) -> bool:
    return Path(name).stem in INTRINSICS


def found(fname: str, location: list[str]) -> bool:
    return len(location) > 0


def locate(fname: str) -> list[str]:
    """
    Where is the file `fname` found? Go over the directories of SRC_DIRS
    and register where it is sound.
    """
    result: list[str] = []  # if it's empty: the file is not found
    for dir in SRC_DIRS:
        if os.path.isfile(f"{dir}/{fname}"):
            result.append(dir)
        #
    #
    return result


## GraphViz #################################################################


class GraphViz:
    def __init__(self, parent: "Graph", graph: dict) -> None:
        self.parent = parent
        self.graph = graph
        self.dot_file = "deps.dot"
        self.png_file = "deps.png"

    def create_dot_file(self) -> None:
        header = """
digraph D {
    // graph [concentrate=true];
    // layout=neato;
    // rankdir=LR;
    // edge [dir=none];

"""
        header += '    "{0}" [fillcolor=green, style=filled];'.format(self.parent.fname)
        footer = """
}
""".strip()
        f = open(self.dot_file, "w")
        print(header, file=f)
        print(file=f)
        for k, values in self.graph.items():
            s = " ".join('"' + v + '"' for v in values)
            print('    "{a}" -> {{{b}}};'.format(a=k, b=s), file=f)
        print(footer, file=f)
        f.close()

    def create_png_file(self) -> None:
        cmd = f"dot -T png {self.dot_file} -o {self.png_file}"
        print("#", cmd)
        status = os.system(cmd)
        if status != 0:
            print("Error: the command `dot` is missing?")
            print("Tip: install the graphviz package")
        #

    def start(self):
        self.create_dot_file()
        self.create_png_file()


## GFortran #################################################################


class GFortran:
    def __init__(self, parent: "Graph") -> None:
        self.parent = parent
        self.compiler = "gfortran"
        if not os.path.isdir("mod"):
            try:
                os.mkdir("mod")
            except:  # noqa
                print("Error: cannot create the directory mod/", file=sys.stderr)
                exit(3)
            #
        #

    def get_compile_command(self) -> str:
        cmd = f"{self.compiler} -Jmod -Imod "
        cmd = cmd + " ".join(self.parent.filenames_with_paths())
        return cmd

    def get_run_command(self) -> str:
        cli_args = [f'"{arg}"' for arg in self.parent.arguments]
        cmd = "./a.out"
        if cli_args:
            cmd += " " + " ".join(cli_args)
        return cmd

    def get_compile_and_run_command(self) -> str:
        compile = self.get_compile_command()
        run = self.get_run_command()
        cmd = f"{compile} && {run}"
        return cmd


## Graph ####################################################################


class Graph:
    def __init__(self, fname: str, options: list[str], arguments: list[str]) -> None:
        self.fname: str = fname
        self.options: list[str] = options
        self.arguments: list[str] = arguments
        # dependencies, file_name: [included_file_1, included_file_2, ...]
        self.deps: defaultdict[str, list[str]] = defaultdict(list)
        self.filenames: list[str] = []  # files to compile in the correct order
        self.location: dict[str, str] = {}  # location of a source file
        self.all_sources: list[str] = self.collect_all_sources()

    def filenames_with_paths(self) -> list[str]:
        return [self.get_path(f) for f in self.filenames]

    def collect_all_sources(self) -> list[str]:
        result: list[str] = []

        base = os.getcwd()
        for path, dirs, files in os.walk(base):
            for f in files:
                p = Path(f)
                if p.suffix in SOURCE_EXTENSIONS:
                    fullname = os.path.join(path, f)
                    relative = Path(fullname).relative_to(base)
                    result.append(str(relative))
                #
            #
        #
        return result

    def start(self) -> None:
        self.process(self.fname)
        if Options["info"]:
            print("Dependencies:")
            print("=============")
            pprint(dict(self.deps))
            print("---")
        #
        if Options["info"]:
            print("Dependency graph visualization:")
            print("===============================")
            gv = GraphViz(self, dict(self.deps))
            print(f"See `{gv.png_file}`")
            gv.start()
            print("---")
        #
        self.traverse(self.fname)
        if Options["info"]:
            print("Compilation order:")
            print("==================")
            print(self.filenames)
            print("with paths:")
            print(self.filenames_with_paths())
            print("---")
        #
        unused = sorted(
            set(self.all_sources).difference(set(self.filenames_with_paths()))
        )
        if Options["info"] and unused:
            print("Unused source files:")
            print("====================")
            print("Maybe you can delete them?")
            print(unused)
            print("---")
        #
        gf = GFortran(self)
        if Options["info"]:
            print("Compile and run:")
            print("================")
            cmd = gf.get_compile_command()
            print("#", cmd)
            cmd = gf.get_run_command()
            print("#", cmd)
        #
        if Options["compile"] and Options["run"]:
            cmd = gf.get_compile_and_run_command()
            print("#", cmd)
            os.system(cmd)
        elif Options["compile"]:
            cmd = gf.get_compile_command()
            print("#", cmd)
            os.system(cmd)
        elif Options["run"]:
            cmd = gf.get_run_command()
            print("#", cmd)
            os.system(cmd)

    def add_to_set(self, fname: str) -> None:
        if fname not in self.filenames:
            self.filenames.append(fname)

    def traverse(self, fname: str) -> None:
        for f in self.deps.get(fname, []):
            self.traverse(f)
            self.add_to_set(f)
        #
        self.add_to_set(fname)

    def check(self, fname: str, location: list[str]) -> None:
        # it can be present max. 1x
        if len(location) > 1:
            print(f"Error: the file {fname} is present in multiple folders: {location}")
            exit(1)
        #

    def get_path(self, fname: str) -> str:
        loc = self.location[fname]
        if loc == ".":
            return fname
        # else
        return loc + "/" + fname

    def is_it_a_module_in_the_same_file(self, name: str, lines: list[str]) -> bool:
        for line in lines:
            line = line.strip().lower()
            if line.startswith("module "):
                parts = line.split()
                token = parts[1]
                if token == name:
                    return True
                #
            #
        #
        return False

    def collect_modules_and_uses(self, lines: list[str]) -> tuple[list[str], list[str]]:
        """
        Go over the lines of the file and extract
        (1) module names ("module <name>"), and
        (2) used module name ("use <mod>")
        Intrinsic modules are discarded.
        """
        modules: list[str] = []
        uses: list[str] = []

        for line in lines:
            line = line.strip().lower()
            if line.startswith("module "):
                parts = line.split()
                module_name = parts[1]
                modules.append(module_name)
            elif line.startswith("use "):
                if "intrinsic" in line:
                    continue  # skip it
                # else:
                left = line.split(",")[0]
                use_name = left.removeprefix("use ").strip()
                if is_intrinsic(use_name):
                    continue  # skip it
                # else:
                uses.append(use_name)
            #
        #
        return (modules, uses)

    def process(self, fname: str, who_uses_it=None) -> None:
        """
        This file must be present to successfully compile the project.
        """
        if is_intrinsic(fname):
            return
        # else, it must be present:
        loc = locate(fname)
        self.check(fname, loc)  # check if it's present just once
        if not found(fname, loc):
            print(f"Error: the file {fname} is missing")
            if who_uses_it:
                print("It's used here:", self.get_path(who_uses_it))
            exit(5)
        # if the file exists and it's present just once:
        self.location[fname] = loc[0]
        with open(self.get_path(fname)) as f:
            lines = f.read().splitlines()
        #
        modules, uses = self.collect_modules_and_uses(lines)
        #
        for use_name in uses:
            if use_name in modules:
                continue  # skip it, this is a module in the same file
            # else:
            child_without_ext = use_name
            child = child_without_ext + ".f90"

            loc = locate(child)
            self.check(child, loc)
            if found(child, loc):
                self.deps[fname].append(child)
            #
            if child not in self.deps:
                self.process(child, who_uses_it=fname)
            #
        #


##############################################################################


def print_help() -> None:
    help = """
ezf - easily compile and run Fortran programs

Usage: ezf [options] main.f90 [-- arguments]
Options:
-h, --help          this help
-i, --info          show all info (don't compile; don't run)
-c                  compile
-r                  run
-cr                 compile and run (default if no options are given)
""".strip()
    print(help)


def check_arguments() -> tuple[str, list[str], list[str]]:
    args = sys.argv[1:]
    if len(args) == 0:
        print_help()
        exit(0)
    # else:
    options = []  # options for this script
    arguments = []  # arguements for the Fortran program
    if "--" in args:
        pos = args.index("--")
        options = args[:pos]
        arguments = args[pos + 1 :]
    else:
        options = args
    #
    if ("-h" in options) or ("--help" in options):
        print_help()
        exit(0)
    # else:
    try:
        fname = options.pop()
        if not os.path.isfile(fname):
            raise FileNotFoundError
    except IndexError:
        print("Error: provide a file name (ex.: main.f90)", file=sys.stderr)
        exit(1)
    except FileNotFoundError:
        print(f"Error: the file `{fname}` is not found", file=sys.stderr)
        exit(2)
    # else, fname exists:
    no_options = len(options) == 0
    #
    if ("-i" in options) or ("--info" in options):
        Options["info"] = True
        if "-i" in options:
            options.remove("-i")
        if "--info" in options:
            options.remove("--info")
        #
    #
    if no_options:
        options.append("-cr")  # default
    if "-c" in options:
        Options["compile"] = True
        options.remove("-c")
    if "-r" in options:
        Options["run"] = True
        options.remove("-r")
    if "-cr" in options:
        Options["compile"] = True
        Options["run"] = True
        options.remove("-cr")
    #
    if options:
        print("Unknown option(s):", options, file=sys.stderr)
        exit(6)
    #
    return (fname, options, arguments)


def main():
    fname, options, arguments = check_arguments()

    g = Graph(fname, options, arguments)
    g.start()


##############################################################################

if __name__ == "__main__":
    main()
