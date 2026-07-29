# Task 10.2.4 Initializing Formals Hotfix

The public constructor keeps these named parameters:

- `pathResolver`
- `fileSystem`
- `transactionIdFactory`

A private positional constructor initializes the private fields directly, so
`prefer_initializing_formals` passes without changing callers or suppressing
the lint.
