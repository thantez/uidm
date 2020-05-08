from itertools import chain, combinations


def read_dataset(file_address):
    """ Read transactions """
    with open(file_address, 'r') as file:
        dataset = []
        for line in file:
            items = line.rstrip().split('|')
            dataset.append(items)
        return len(dataset)


def read_frequent_itemsets(file_address):
    """ Read frequent itemsets caculated by algorithmns and convert its format """
    with open(file_address, 'r') as file:
        itemsets = {}
        for line in file:
            data = line.rstrip().split('|')
            data = list(map(str.strip, data))
            items = frozenset(data[:-1])
            frequency = int(data[-1])
            itemsets[items] = frequency
        return itemsets


def subsets(arr):
    """ Returns non empty subsets of arr"""
    return chain(*[combinations(arr, i + 1) for i, a in enumerate(arr)])


def get_rules(transactions_count, frequent_itemsets, min_confidence):
    """ Calculate association rules base on min_confidence """
    rules = []
    for itemset, itemset_frequency in frequent_itemsets.items():
        _subsets = map(frozenset, [x for x in subsets(itemset)])
        for element in _subsets:
            remain = itemset.difference(element)
            if len(remain) > 0:
                itemset_support = itemset_frequency / transactions_count
                element_support = frequent_itemsets[element] / \
                    transactions_count
                confidence = itemset_support / element_support
                if confidence >= min_confidence:
                    remain_support = frequent_itemsets[remain] / transactions_count
                    lift = confidence / remain_support
                    rules.append((list(element), list(remain), confidence, lift))
    return rules


def print_rules(rules):
    for rule in rules:
        X, Y, confidence, lift = rule
        print(f'[C: {confidence:.2f}, L: {lift:.2f}] {X} --> {Y}')


def main():
    frequent_itemsets = read_frequent_itemsets('results/apriori_frequents.txt')
    transactions_count = read_dataset('data/transactions_items.txt')
    rules = get_rules(
        transactions_count=transactions_count,
        frequent_itemsets=frequent_itemsets,
        min_confidence=0.5
    )
    # print_rules(rules)
    print('Rules count:', len(rules))


main()
