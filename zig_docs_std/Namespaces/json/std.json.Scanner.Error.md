# std.json.Scanner.Error

The parsing errors are divided into two categories:

- `SyntaxError` is for clearly malformed JSON documents, such as giving an input document that isn't JSON at all.
- `UnexpectedEndOfInput` is for signaling that everything's been valid so far, but the input appears to be truncated for some reason. Note that a completely empty (or whitespace-only) input will give `UnexpectedEndOfInput`.

## Errors

SyntaxError  

UnexpectedEndOfInput  
