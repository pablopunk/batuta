export type Token = { text: string; kind?: string };

const KEYWORDS = new Set([
  "import", "enum", "case", "init", "switch", "self", "default", "return", "nil", "private", "static", "let", "var",
  "final", "class", "func", "struct", "guard", "else", "if", "for", "in", "true", "false",
]);

const TOKEN = /(\/\/.*)|("[^"]*")|(@\w+)|(\b\d+\b)|(\.[a-z]\w*)|(\b[A-Z]\w*)|(\b[a-z]\w*(?=\())|(\b\w+\b)|(\s+|.)/g;

const KIND_BY_GROUP = ["comment", "string", "attribute", "number", "member", "type", "call"];

export function highlightSwift(line: string): Token[] {
  return Array.from(line.matchAll(TOKEN), (match) => {
    const groupIndex = match.slice(1).findIndex((group) => group !== undefined);
    const text = match[0];
    if (groupIndex < KIND_BY_GROUP.length) return { text, kind: KIND_BY_GROUP[groupIndex] };
    return KEYWORDS.has(text) ? { text, kind: "keyword" } : { text };
  });
}
