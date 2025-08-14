import fs from 'fs';
const natural = require('natural');

// Check if the correct number of arguments are provided
if (process.argv.length !== 4) {
    console.error('Usage: node doc-processor <task> <input_file>');
    process.exit(1);
}

const task = process.argv[2];
const inputFile = process.argv[3];

// Read the input file
fs.readFile(inputFile, 'utf8', (err, data) => {
    if (err) {
        console.error(`Error reading input file: ${err}`);
        process.exit(1);
    }

    switch (task) {
        case 'summarize':
            summarize(data);
            break;
        case 'extract-keywords':
            extractKeywords(data);
            break;
        default:
            console.error(`Unknown task: ${task}`);
            process.exit(1);
    }
});

function summarize(text) {
    const tokenizer = new natural.SentenceTokenizer();
    const sentences = tokenizer.tokenize(text);
    const tfidf = new natural.TfIdf();
    tfidf.addDocument(text);

    const sentenceScores = [];
    for (let i = 0; i < sentences.length; i++) {
        let score = 0;
        const terms = new natural.WordTokenizer().tokenize(sentences[i].toLowerCase());
        for (let j = 0; j < terms.length; j++) {
            score += tfidf.tfidf(terms[j], 0);
        }
        sentenceScores.push({ sentence: sentences[i], score: score });
    }

    sentenceScores.sort((a, b) => b.score - a.score);

    const summary = sentenceScores.slice(0, 3).map(item => item.sentence).join(' ');
    console.log(summary);
}

function extractKeywords(text) {
    const tfidf = new natural.TfIdf();
    tfidf.addDocument(text);

    const keywords = [];
    tfidf.listTerms(0).slice(0, 10).forEach(item => {
        keywords.push(item.term);
    });

    console.log(keywords.join(', '));
}
