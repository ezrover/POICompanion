import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const TASKS_FILE = path.join(__dirname, 'tasks.json');

// Load tasks from file, or return empty array if file doesn't exist
function loadTasks() {
    if (fs.existsSync(TASKS_FILE)) {
        const data = fs.readFileSync(TASKS_FILE, 'utf8');
        return JSON.parse(data);
    }
    return [];
}

// Save tasks to file
function saveTasks(tasks) {
    fs.writeFileSync(TASKS_FILE, JSON.stringify(tasks, null, 2));
}

// Check if the correct number of arguments are provided
if (process.argv.length < 3) {
    console.error('Usage: node task-manager <command> [args]');
    process.exit(1);
}

const command = process.argv[2];

switch (command) {
    case 'add':
        addTask(process.argv[3], process.argv[4], process.argv[5]);
        break;
    case 'list':
        listTasks();
        break;
    case 'update':
        updateTask(process.argv[3], process.argv[4], process.argv[5]);
        break;
    default:
        console.error(`Unknown command: ${command}`);
        process.exit(1);
}

function addTask(description, priority, assignee) {
    if (!description) {
        console.error('Usage: node task-manager add <description> [priority] [assignee]');
        process.exit(1);
    }
    const tasks = loadTasks();
    const newTask = {
        id: tasks.length > 0 ? Math.max(...tasks.map(task => task.id)) + 1 : 1,
        description,
        priority: priority || 'medium',
        assignee: assignee || 'unassigned',
        status: 'pending',
        createdAt: new Date().toISOString()
    };
    tasks.push(newTask);
    saveTasks(tasks);
    console.log('Task added:', newTask);
}

function listTasks() {
    const tasks = loadTasks();
    if (tasks.length === 0) {
        console.log('No tasks found.');
        return;
    }
    console.log('Tasks:');
    tasks.forEach(task => {
        console.log(`ID: ${task.id}, Description: ${task.description}, Priority: ${task.priority}, Assignee: ${task.assignee}, Status: ${task.status}`);
    });
}

function updateTask(id, field, value) {
    if (!id || !field || !value) {
        console.error('Usage: node task-manager update <id> <field> <value>');
        process.exit(1);
    }
    const tasks = loadTasks();
    const taskIndex = tasks.findIndex(task => task.id === parseInt(id));
    if (taskIndex === -1) {
        console.error(`Task with ID ${id} not found.`);
        process.exit(1);
    }
    tasks[taskIndex][field] = value;
    saveTasks(tasks);
    console.log('Task updated:', tasks[taskIndex]);
}
