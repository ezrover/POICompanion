const fs = require('fs-extra');
const path = require('path');

// Check if the correct number of arguments are provided
if (process.argv.length !== 4) {
    console.error('Usage: node project-scaffolder <project_type> <project_name>');
    process.exit(1);
}

const projectType = process.argv[2];
const projectName = process.argv[3];

const projectPath = path.join(process.cwd(), projectName);

// Create the project directory
fs.ensureDir(projectPath)
    .then(() => {
        switch (projectType) {
            case 'react-app':
                scaffoldReactApp();
                break;
            case 'node-api':
                scaffoldNodeApi();
                break;
            default:
                console.error(`Unknown project type: ${projectType}`);
                process.exit(1);
        }
    })
    .catch(err => {
        console.error(`Error creating project directory: ${err}`);
        process.exit(1);
    });

function scaffoldReactApp() {
    console.log(`Scaffolding React app: ${projectName}`);
    fs.ensureDir(path.join(projectPath, 'src'))
        .then(() => {
            fs.ensureDir(path.join(projectPath, 'public'))
                .then(() => {
                    fs.writeFile(path.join(projectPath, 'src', 'index.js'), '// Entry point for the React app');
                    fs.writeFile(path.join(projectPath, 'public', 'index.html'), '<html><body><div id="root"></div></body></html>');
                    fs.writeFile(path.join(projectPath, 'package.json'), JSON.stringify({ name: projectName, version: '1.0.0' }, null, 2));
                    console.log('React app scaffolded successfully.');
                })
        })
        .catch(err => {
            console.error(`Error scaffolding React app: ${err}`);
        });
}

function scaffoldNodeApi() {
    console.log(`Scaffolding Node.js API: ${projectName}`);
    fs.ensureDir(path.join(projectPath, 'src'))
        .then(() => {
            fs.writeFile(path.join(projectPath, 'src', 'index.js'), '// Entry point for the Node.js API');
            fs.writeFile(path.join(projectPath, 'package.json'), JSON.stringify({ name: projectName, version: '1.0.0', main: 'src/index.js' }, null, 2));
            console.log('Node.js API scaffolded successfully.');
        })
        .catch(err => {
            console.error(`Error scaffolding Node.js API: ${err}`);
        });
}
