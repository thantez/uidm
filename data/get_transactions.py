import csv

transactions = {}

with open('Online_Shopping.csv') as file:
    dataset = csv.DictReader(file)
    
    for data in dataset:
        invoice_no = data['InvoiceNo']

        if invoice_no not in transactions:
            transactions[invoice_no] = []

        description = data['Description'].strip()
        # Ignore broken data (empty description or mannual transactions)
        if description.isupper():
            transactions[invoice_no].append(description)

with open('transactions_items.txt', 'w') as file:
    for key, items in transactions.items():
        if len(items):
            line = '|'.join(items) + '\n'
            file.write(line)
