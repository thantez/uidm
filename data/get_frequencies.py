items_count = {}

with open('transactions_items.txt') as file:
    for line in file:
        items = line.rstrip().split('|')
        for item in items:
            count = items_count.get(item, 0)
            items_count[item] = count + 1

with open('items_frequencies.txt', 'w') as file:
    for key, count in items_count.items():
        file.write(f'{key}|{count}\n')