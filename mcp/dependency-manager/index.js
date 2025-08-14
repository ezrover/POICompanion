const fs = require('fs');
const path = require('path');

const DEPENDENCIES_FILE = path.join(__dirname, 'dependencies.json');

// Load dependencies from file, or return default if file doesn't exist
function loadDependencies() {
    if (fs.existsSync(DEPENDENCIES_FILE)) {
        const data = fs.readFileSync(DEPENDENCIES_FILE, 'utf8');
        return JSON.parse(data);
    }
    return [
        { name: 'react', version: '18.2.0' },
        { name: 'react-dom', version: '18.2.0' },
        { name: 'express', version: '4.18.2' }
    ];
}

// Save dependencies to file
function saveDependencies(deps) {
    fs.writeFileSync(DEPENDENCIES_FILE, JSON.stringify(deps, null, 2));
}

let dependencies = loadDependencies();

// Check if the correct number of arguments are provided
if (process.argv.length < 3) {
    console.error('Usage: node dependency-manager <command> [args]');
    process.exit(1);
}

const command = process.argv[2];

switch (command) {
    case 'install':
        installDependency(process.argv[3]);
        break;
    case 'update':
        updateDependencies(process.argv[3]);
        break;
    case 'list':
        listDependencies();
        break;
    default:
        console.error(`Unknown command: ${command}`);
        process.exit(1);
}

function installDependency(name) {
    if (!name) {
        console.error('Usage: node dependency-manager install <dependency_name>');
        process.exit(1);
    }
    const existing = dependencies.find(dep => dep.name === name);
    if (existing) {
        console.log(`Dependency ${name} is already installed.`);
    } else {
        dependencies.push({ name, version: 'latest' }); // Simulate installing latest
        saveDependencies(dependencies);
        console.log(`Dependency ${name} installed successfully.`);
    }
}

function updateDependencies(option) {
    if (option === '--all') {
        dependencies = dependencies.map(dep => ({ ...dep, version: 'updated' }));
        saveDependencies(dependencies);
        console.log('All dependencies updated successfully (simulated).');
    } else {
        console.error('Usage: node dependency-manager update --all');
        process.exit(1);
    }
}

function listDependencies() {
    console.log('Current Dependencies:');
    if (dependencies.length === 0) {
        console.log('No dependencies found.');
        return;
    }
    dependencies.forEach(dep => {
        console.log(`- ${dep.name}@${dep.version}`);
    });
}
