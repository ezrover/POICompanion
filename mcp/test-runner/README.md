# Test Runner

This tool provides a unified interface to run different types of tests.

## Usage

```bash
node test-runner <test_type> [options]
```

-   `<test_type>`: The type of tests to run. Can be `unit`, `integration`, `e2e`.
-   `[options]`: Optional arguments for the test runner.

## Examples

```bash
node test-runner unit
node test-runner integration --scope=auth
```
