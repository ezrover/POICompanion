const fs = require('fs');
const Ajv = require('ajv');
const addFormats = require('ajv-formats');
const ajv = new Ajv();
addFormats(ajv);

// Check if the correct number of arguments are provided
if (process.argv.length !== 4) {
    console.error('Usage: node schema-validator <data_file> <schema_file>');
    process.exit(1);
}

const dataFile = process.argv[2];
const schemaFile = process.argv[3];

// Read the data file
fs.readFile(dataFile, 'utf8', (err, dataSource) => {
    if (err) {
        console.error(`Error reading data file: ${err}`);
        process.exit(1);
    }

    // Read the schema file
    fs.readFile(schemaFile, 'utf8', (err, schemaSource) => {
        if (err) {
            console.error(`Error reading schema file: ${err}`);
            process.exit(1);
        }

        try {
            const data = JSON.parse(dataSource);
            const schema = JSON.parse(schemaSource);

            const validate = ajv.compile(schema);
            const valid = validate(data);

            if (valid) {
                console.log('Data is valid against the schema.');
            } else {
                console.error('Data is NOT valid against the schema.');
                console.error(validate.errors);
            }
        } catch (err) {
            console.error(`Error parsing JSON files: ${err}`);
            process.exit(1);
        }
    });
});
