import fs from 'fs';
import path from 'path';

// Check if the correct number of arguments are provided
if (process.argv.length < 4) {
    console.error('Usage: node ui-generator <component_type> <component_name> [properties_json]');
    process.exit(1);
}

const componentType = process.argv[2];
const componentName = process.argv[3];
const propertiesJson = process.argv[4];

let properties = {};
if (propertiesJson) {
    try {
        properties = JSON.parse(propertiesJson);
    } catch (e) {
        console.error('Error parsing properties JSON:', e);
        process.exit(1);
    }
}

console.log(`Generating UI component: ${componentName} of type ${componentType}...`);

let generatedCode = '';

switch (componentType) {
    case 'button':
        generatedCode = `// ${componentName}.js (Button Component)\nimport React from 'react';\n\nconst ${componentName} = ({ text, color }) => (\n  <button style={{ backgroundColor: color }}>{text}</button>\n);\n\nexport default ${componentName};\n`;
        break;
    case 'card':
        generatedCode = `// ${componentName}.js (Card Component)\nimport React from 'react';\n\nconst ${componentName} = ({ title, content }) => (\n  <div style={{ border: '1px solid gray', padding: '10px' }}>\n    <h3>{title}</h3>\n    <p>{content}</p>\n  </div>\n);\n\nexport default ${componentName};\n`;
        break;
    case 'form':
        generatedCode = `// ${componentName}.js (Form Component)\nimport React from 'react';\n\nconst ${componentName} = () => (\n  <form>\n    <input type="text" placeholder="Name" />\n    <button type="submit">Submit</button>\n  </form>\n);\n\nexport default ${componentName};\n`;
        break;
    default:
        console.error(`Unknown component type: ${componentType}`);
        process.exit(1);
}

const outputFileName = `${componentName}.js`;
const outputPath = path.join(process.cwd(), outputFileName);

fs.writeFile(outputPath, generatedCode, (err) => {
    if (err) {
        console.error(`Error writing generated UI component file: ${err}`);
        process.exit(1);
    }
    console.log(`Successfully generated UI component: ${outputPath}`);
});
