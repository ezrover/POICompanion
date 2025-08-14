# UI Generator

This tool generates UI components and mockups from a design specification.

## Usage

```bash
node ui-generator <component_type> <component_name> [properties_json]
```

-   `<component_type>`: The type of UI component to generate (e.g., `button`, `card`, `form`).
-   `<component_name>`: The name of the component.
-   `[properties_json]`: Optional. A JSON string of properties for the component.

## Examples

```bash
node ui-generator button PrimaryButton '{"text": "Click Me", "color": "blue"}'
node ui-generator card UserProfileCard
```
