import csv
import sys

invoices = {}
stock_codes = {}

with open('Online_Shopping.csv') as csvfile:
    dataset = csv.DictReader(csvfile)
    for a_set in dataset:
        description = a_set['Description']
        stock_code = a_set['StockCode']

        if description.isupper():
            if not stock_codes.get(stock_code):
                stock_codes[stock_code] = description.strip()

with open('Online_Shopping.csv') as csvfile:
    dataset = csv.DictReader(csvfile)
    for a_set in dataset:
        invoice_no = a_set['InvoiceNo']
        stock_code = a_set['StockCode']

        transaction = invoices.get(invoice_no, [])
        item = stock_codes.get(stock_code, '')

        if item:
            transaction.append(item)
            invoices[invoice_no] = transaction

with open('transactions.csv', 'w') as transactions_file:
    field_names = ['tid', 'itemset']
    transactions_csv = csv.DictWriter(transactions_file, fieldnames=field_names, delimiter='|',
                                      quotechar='"', quoting=csv.QUOTE_MINIMAL, dialect='excel')
    transactions_csv.writeheader()

    for tid, itemset in invoices.items():
        unique_itemset = list(set(itemset))
        transactions_csv.writerow({'tid': tid, 'itemset': unique_itemset})

with open('transactions.result', 'w') as transactions_file:
    for tid, itemset in invoices.items():
        unique_itemset = list(set(itemset))
        for item in unique_itemset:
            transactions_file.write("%s|" % item)
        transactions_file.write("\n")
