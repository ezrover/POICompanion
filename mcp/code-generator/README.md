# Code Generator

This tool generates boilerplate code for different components and services.

## Usage

```bash
node code-generator <component_type> <component_name> [output_dir]
```

-   `<component_type>`: The type of component to generate. Can be `react-component`, `node-module`.
-   `<component_name>`: The name of the component.
-   `[output_dir]`: Optional. The directory where the component will be generated. Defaults to current directory.

## Examples

```bash
node code-generator react-component MyButton
node code-generator node-module MyUtility components
```
