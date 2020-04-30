import csv

items = {}

with open('transactions.result') as transactions_file:
    for transaction in transactions_file:
        dirty_itemset = list(transaction.split("|"))
        itemset = filter(str.strip, dirty_itemset)
        for item in itemset:
            item_frequency = items.get(item, 0)
            item_frequency += 1
            items[item] = item_frequency

with open('frequencies.csv', 'w') as frequencies_file:
    field_names = ['item', 'frequency']
    frequencies_csv = csv.DictWriter(frequencies_file, fieldnames=field_names, delimiter='|')
    frequencies_csv.writeheader()

    for item_name, item_frequency in items.items():
        frequencies_csv.writerow({'item': item_name, 'frequency': item_frequency})
