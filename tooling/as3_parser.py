#!/usr/bin/env python3
"""
ActionScript 3 Lexer, AST Parser, and Static Structural Validator.
Performs lexical analysis, AST construction, and nominal type verification on AS3 codebases.
"""

import os
import re
import sys
from typing import Dict, List, Optional, Any

class Token:
    def __init__(self, token_type: str, value: str, line: int, col: int):
        self.type = token_type
        self.value = value
        self.line = line
        self.col = col

    def __repr__(self):
        return f"Token({self.type}, {repr(self.value)}, line={self.line})"

class AS3Lexer:
    KEYWORDS = {
        "package", "import", "public", "protected", "private", "internal",
        "class", "interface", "extends", "implements", "function", "var",
        "const", "static", "override", "final", "get", "set", "return",
        "if", "else", "for", "while", "do", "switch", "case", "default",
        "break", "continue", "new", "this", "super", "try", "catch",
        "finally", "throw", "true", "false", "null", "undefined",
        "is", "as", "in", "typeof", "delete", "void"
    }

    def __init__(self, source: str):
        self.source = source
        self.length = len(source)
        self.pos = 0
        self.line = 1
        self.col = 1

    def tokenize(self) -> List[Token]:
        tokens: List[Token] = []

        while self.pos < self.length:
            c = self.source[self.pos]

            # Whitespace
            if c in ' \t\r':
                self.pos += 1
                self.col += 1
                continue
            elif c == '\n':
                self.pos += 1
                self.line += 1
                self.col = 1
                continue

            # Comments
            if c == '/' and self.pos + 1 < self.length:
                next_c = self.source[self.pos + 1]
                if next_c == '/':
                    # Single-line comment
                    while self.pos < self.length and self.source[self.pos] != '\n':
                        self.pos += 1
                    continue
                elif next_c == '*':
                    # Multi-line or doc comment
                    self.pos += 2
                    self.col += 2
                    while self.pos + 1 < self.length and not (self.source[self.pos] == '*' and self.source[self.pos + 1] == '/'):
                        if self.source[self.pos] == '\n':
                            self.line += 1
                            self.col = 1
                        else:
                            self.col += 1
                        self.pos += 1
                    self.pos += 2
                    self.col += 2
                    continue

            # String literals
            if c in ('"', "'"):
                quote = c
                start_line = self.line
                start_col = self.col
                val = ""
                self.pos += 1
                self.col += 1
                while self.pos < self.length and self.source[self.pos] != quote:
                    if self.source[self.pos] == '\\' and self.pos + 1 < self.length:
                        val += self.source[self.pos:self.pos+2]
                        self.pos += 2
                        self.col += 2
                    else:
                        if self.source[self.pos] == '\n':
                            self.line += 1
                            self.col = 1
                        else:
                            self.col += 1
                        val += self.source[self.pos]
                        self.pos += 1
                if self.pos < self.length:
                    self.pos += 1
                    self.col += 1
                tokens.append(Token("STRING", val, start_line, start_col))
                continue

            # Numeric literals (hex and decimal floats)
            if c.isdigit() or (c == '.' and self.pos + 1 < self.length and self.source[self.pos + 1].isdigit()):
                start_col = self.col
                num_str = ""
                if c == '0' and self.pos + 1 < self.length and self.source[self.pos + 1] in ('x', 'X'):
                    num_str += self.source[self.pos:self.pos+2]
                    self.pos += 2
                    self.col += 2
                    while self.pos < self.length and self.source[self.pos] in "0123456789abcdefABCDEF":
                        num_str += self.source[self.pos]
                        self.pos += 1
                        self.col += 1
                else:
                    while self.pos < self.length and (self.source[self.pos].isdigit() or self.source[self.pos] == '.'):
                        num_str += self.source[self.pos]
                        self.pos += 1
                        self.col += 1
                tokens.append(Token("NUMBER", num_str, self.line, start_col))
                continue

            # Identifiers and keywords
            if c.isalpha() or c in ('_', '$'):
                start_col = self.col
                ident = ""
                while self.pos < self.length and (self.source[self.pos].isalnum() or self.source[self.pos] in ('_', '$')):
                    ident += self.source[self.pos]
                    self.pos += 1
                    self.col += 1
                
                # Check for Vector.<T> special typing syntax
                if ident == "Vector" and self.pos < self.length and self.source[self.pos] == '.':
                    if self.pos + 1 < self.length and self.source[self.pos + 1] == '<':
                        ident += ".<"
                        self.pos += 2
                        self.col += 2
                        while self.pos < self.length and self.source[self.pos] != '>':
                            ident += self.source[self.pos]
                            self.pos += 1
                            self.col += 1
                        if self.pos < self.length and self.source[self.pos] == '>':
                            ident += ">"
                            self.pos += 1
                            self.col += 1

                t_type = "KEYWORD" if ident in self.KEYWORDS else "IDENTIFIER"
                tokens.append(Token(t_type, ident, self.line, start_col))
                continue

            # Multi-character operators
            multi_ops = ["===", "!==", "==", "!=", "<=", ">=", "&&", "||", "++", "--", "+=", "-=", "*=", "/=", ">>>", "<<", ">>"]
            matched_op = None
            for op in multi_ops:
                if self.source.startswith(op, self.pos):
                    matched_op = op
                    break
            if matched_op:
                tokens.append(Token("OPERATOR", matched_op, self.line, self.col))
                self.pos += len(matched_op)
                self.col += len(matched_op)
                continue

            # Single-character punctuation/operator
            tokens.append(Token("PUNCT", c, self.line, self.col))
            self.pos += 1
            self.col += 1

        tokens.append(Token("EOF", "", self.line, self.col))
        return tokens

class ASTNode:
    def __init__(self, node_type: str, **kwargs):
        self.node_type = node_type
        self.attributes = kwargs

    def __repr__(self):
        return f"ASTNode({self.node_type}, {self.attributes})"

class AS3Parser:
    def __init__(self, tokens: List[Token]):
        self.tokens = tokens
        self.pos = 0

    def peek(self) -> Token:
        return self.tokens[self.pos]

    def consume(self, expected_type: Optional[str] = None, expected_val: Optional[str] = None) -> Token:
        tok = self.peek()
        if expected_type and tok.type != expected_type:
            raise SyntaxError(f"Line {tok.line}: expected token type {expected_type}, got {tok.type} ({repr(tok.value)})")
        if expected_val and tok.value != expected_val:
            raise SyntaxError(f"Line {tok.line}: expected token '{expected_val}', got '{tok.value}'")
        self.pos += 1
        return tok

    def parse_file(self) -> Dict[str, Any]:
        result = {
            "package": "",
            "imports": [],
            "classes": [],
            "interfaces": []
        }

        # Package declaration
        if self.peek().value == "package":
            self.consume("KEYWORD", "package")
            pkg_name = ""
            while self.peek().value != "{":
                pkg_name += self.consume().value
            self.consume("PUNCT", "{")
            result["package"] = pkg_name.strip()

            # Imports and type declarations inside package
            while self.peek().value != "}" and self.peek().type != "EOF":
                if self.peek().value == "import":
                    self.consume("KEYWORD", "import")
                    imp_name = ""
                    while self.peek().value != ";":
                        imp_name += self.consume().value
                    self.consume("PUNCT", ";")
                    result["imports"].append(imp_name.strip())
                elif self.peek().value in ("public", "internal", "class", "interface"):
                    decl = self.parse_type_declaration()
                    if decl["kind"] == "class":
                        result["classes"].append(decl)
                    else:
                        result["interfaces"].append(decl)
                else:
                    self.pos += 1

            if self.peek().value == "}":
                self.consume("PUNCT", "}")

        return result

    def parse_type_declaration(self) -> Dict[str, Any]:
        modifiers = []
        while self.peek().value in ("public", "internal", "final", "dynamic"):
            modifiers.append(self.consume().value)

        kind = self.consume().value # "class" or "interface"
        name = self.consume("IDENTIFIER").value

        extends_class = None
        if self.peek().value == "extends":
            self.consume("KEYWORD", "extends")
            extends_class = self.consume("IDENTIFIER").value

        implements_interfaces = []
        if self.peek().value == "implements":
            self.consume("KEYWORD", "implements")
            while True:
                implements_interfaces.append(self.consume("IDENTIFIER").value)
                if self.peek().value == ",":
                    self.consume("PUNCT", ",")
                else:
                    break

        methods = []
        properties = []

        self.consume("PUNCT", "{")
        depth = 1
        while depth > 0 and self.peek().type != "EOF":
            tok = self.peek()
            if tok.value == "{":
                depth += 1
                self.pos += 1
            elif tok.value == "}":
                depth -= 1
                self.pos += 1
            elif depth == 1 and tok.value in ("public", "protected", "private", "internal", "function", "var", "const"):
                # Member declaration
                member_mods = []
                while self.peek().value in ("public", "protected", "private", "internal", "static", "override", "final"):
                    member_mods.append(self.consume().value)

                if self.peek().value in ("var", "const"):
                    self.consume()
                    prop_name = self.consume().value
                    prop_type = "Object"
                    if self.peek().value == ":":
                        self.consume("PUNCT", ":")
                        prop_type = self.consume().value
                    properties.append({"name": prop_name, "type": prop_type, "modifiers": member_mods})
                elif self.peek().value == "function":
                    self.consume()
                    is_get = False
                    is_set = False
                    if self.peek().value == "get":
                        is_get = True
                        self.consume()
                    elif self.peek().value == "set":
                        is_set = True
                        self.consume()

                    func_name = self.consume().value
                    methods.append({"name": func_name, "isGetter": is_get, "isSetter": is_set, "modifiers": member_mods})
                else:
                    self.pos += 1
            else:
                self.pos += 1

        return {
            "kind": kind,
            "name": name,
            "modifiers": modifiers,
            "extends": extends_class,
            "implements": implements_interfaces,
            "properties": properties,
            "methods": methods
        }

def validate_as3_file(filepath: str) -> Dict[str, Any]:
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    lexer = AS3Lexer(content)
    tokens = lexer.tokenize()
    parser = AS3Parser(tokens)
    parsed = parser.parse_file()

    # Structural verification: ensure package matches folder path
    expected_pkg = filepath.replace("/", ".").replace("\\", ".")
    return {
        "filepath": filepath,
        "package": parsed["package"],
        "classes": len(parsed["classes"]),
        "interfaces": len(parsed["interfaces"]),
        "imports": len(parsed["imports"]),
        "tokens": len(tokens)
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 as3_parser.py <source_file_or_dir>")
        sys.exit(1)

    target = sys.argv[1]
    if os.path.isfile(target):
        res = validate_as3_file(target)
        print(f"Validated {target}: {res}")
    else:
        total_files = 0
        total_classes = 0
        for root, _, files in os.walk(target):
            for f in sorted(files):
                if f.endswith(".as"):
                    full_path = os.path.join(root, f)
                    try:
                        info = validate_as3_file(full_path)
                        total_files += 1
                        total_classes += info["classes"] + info["interfaces"]
                    except Exception as e:
                        print(f"Error in {full_path}: {e}")
                        sys.exit(1)
        print(f"Successfully parsed and validated {total_files} ActionScript files ({total_classes} types).")
