import fs from 'fs';
import path from 'path';
import Handlebars from 'handlebars';

// Check if the correct number of arguments are provided
if (process.argv.length !== 5) {
    console.error('Usage: node spec-generator <template_file> <requirements_file> <output_file>');
    process.exit(1);
}

const templateFile = process.argv[2];
const requirementsFile = process.argv[3];
const outputFile = process.argv[4];

// Read the template file
fs.readFile(templateFile, 'utf8', (err, templateSource) => {
    if (err) {
        console.error(`Error reading template file: ${err}`);
        process.exit(1);
    }

    // Read the requirements file
    fs.readFile(requirementsFile, 'utf8', (err, requirementsSource) => {
        if (err) {
            console.error(`Error reading requirements file: ${err}`);
            process.exit(1);
        }

        try {
            const requirements = JSON.parse(requirementsSource);
            const template = Handlebars.compile(templateSource);
            const output = template(requirements);

            // Write the output file
            fs.writeFile(outputFile, output, (err) => {
                if (err) {
                    console.error(`Error writing output file: ${err}`);
                    process.exit(1);
                }

                console.log(`Successfully generated specification file: ${outputFile}`);
            });
        } catch (err) {
            console.error(`Error parsing requirements file: ${err}`);
            process.exit(1);
        }
    });
});
