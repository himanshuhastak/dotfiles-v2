## Summary
The parser raises an error when processing nested enum values.

## Steps to Reproduce
1. Generate headers with nested enum definitions.
2. Run the parser on the generated output.
3. Observe the failure.

## Expected
Nested enums should parse without error.

## Actual
Parser exits with an unsupported enum nesting error.
