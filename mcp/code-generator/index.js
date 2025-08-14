import fs from 'fs-extra';
import path from 'path';

// Check if the correct number of arguments are provided
if (process.argv.length < 4) {
    console.error('Usage: node code-generator <component_type> <component_name> [output_dir]');
    process.exit(1);
}

const componentType = process.argv[2];
const componentName = process.argv[3];
const outputDir = process.argv[4] || process.cwd();

const componentPath = path.join(outputDir, componentName);

// Create the component directory
fs.ensureDir(componentPath)
    .then(() => {
        switch (componentType) {
            case 'react-component':
                generateReactComponent();
                break;
            case 'node-module':
                generateNodeModule();
                break;
            default:
                console.error(`Unknown component type: ${componentType}`);
                process.exit(1);
        }
    })
    .catch(err => {
        console.error(`Error creating component directory: ${err}`);
        process.exit(1);
    });

function generateReactComponent() {
    console.log(`Generating React component: ${componentName} in ${componentPath}`);
    const componentContent = `import React from 'react';\n\nconst ${componentName} = () => {\n  return (\n    <div>\n      <h1>Hello, ${componentName}!</h1>\n    </div>\n  );\n};\n\nexport default ${componentName};\n`;
    fs.writeFile(path.join(componentPath, `${componentName}.js`), componentContent)
        .then(() => console.log('React component generated successfully.'))
        .catch(err => console.error(`Error writing component file: ${err}`));
}

function generateNodeModule() {
    console.log(`Generating Node.js module: ${componentName} in ${componentPath}`);
    const moduleContent = `// ${componentName} module\n\nmodule.exports = () => {\n  console.log('Hello from ${componentName} module!');\n};\n`;
    fs.writeFile(path.join(componentPath, 'index.js'), moduleContent)
        .then(() => console.log('Node.js module generated successfully.'))
        .catch(err => console.error(`Error writing module file: ${err}`));
}
