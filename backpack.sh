#!/usr/local/bin/bash

BACKPACK_FILE='.backpack.txt'

declare -A MERGE_COMBOS
while read -r result ingredients; do
  MERGE_COMBOS[${result%:}]=$ingredients
done < .merge_combinations.txt

function _display_general_help() {
  echo "Here are the following commands"
  echo "* show"
  echo "* search [item]"
  echo "* sort"
  echo "* add [item]"
  echo "* discard [number of item to discard] [item]"
  echo "* merge [item_1_quantity] [item_1] [item_2_quantity] [item_2]"
  echo

  exit 1
}

_initialize_pack() {
  echo "water" >> $BACKPACK_FILE
  echo "tomato" >> $BACKPACK_FILE
}

_show() {
  echo "Total Item Count: $(wc $BACKPACK_FILE | sed -E 's/^[^0-9]*([0-9]+).*$/\1/')"
  sort $BACKPACK_FILE | uniq -c
  echo
}

function _number_of_item_in_pack {
  echo $(grep -E "^$1$" $BACKPACK_FILE | wc | sed -E 's/^[^0-9]*([0-9]+).*$/\1/')
}


_search() {
  echo "You have $(_number_of_item_in_pack $1) $1s remaining in your pack"
  echo
}

_sort_pack() {
  sort -u $BACKPACK_FILE
  echo
}

# doesn't remove the item from the current location
# is not bound to the current location at all
function _add() {
  if [[ $(wc $BACKPACK_FILE | sed -E 's/^[^0-9]*([0-9]+).*$/\1/') -ge 10 ]]; then
    echo "You are exceeding the maximum limit of 10 items in your backpack."
    echo "Run 'back_pack.sh discard [item] [amount]' if you want to discard items."
    return 0
  fi

  echo $1 >> $BACKPACK_FILE
  if [[ $? -eq 0 ]]; then
    echo "Item added successfully to backpack"
  else
    echo "Item failed to add to backpack"
  fi
}

function _matching_combination_for {
  FIRST_AMOUNT=$2
  FIRST_ITEM=$3
  SECOND_AMOUNT=$4
  SECOND_ITEM=$5

  if [[ $FIRST_ITEM = $SECOND_ITEM ]]; then
    return 0
  fi

  for result in ${!MERGE_COMBOS[@]}; do
    INGREDIENTS=${MERGE_COMBOS[$result]}
    if [[ $INGREDIENTS =~ "$FIRST_AMOUNT $FIRST_ITEM" ]] && \
       [[ $INGREDIENTS =~ "$SECOND_AMOUNT $SECOND_ITEM" ]]
    then
      echo $result
      return 1
    fi
  done

  echo 0
}

function _check_if_does_not_have_ingredients_in_pack {
  FIRST_AMOUNT=$2
  FIRST_ITEM=$3
  SECOND_AMOUNT=$4
  SECOND_ITEM=$5

  NUMBER_OF_FIRST_ITEM_IN_PACK=$(_number_of_item_in_pack $FIRST_ITEM)
  NUMBER_OF_SECOND_ITEM_IN_PACK=$(_number_of_item_in_pack $SECOND_ITEM)

  if [[ $NUMBER_OF_FIRST_ITEM_IN_PACK -ge $FIRST_AMOUNT ]] && \
     [[ $NUMBER_OF_SECOND_ITEM_IN_PACK -ge $SECOND_AMOUNT ]]
  then
    return 1
  fi

  return 0
}

function _merge_help() {
  echo "This may not be a valid combination."
  echo "Ensure that your pack has all of the items that you want to use."
  echo "merge [item_1_quantity] [item_1] [item_2_quantity] [item_2]"
  echo
}

function _merge() {
  RESULT=$(_matching_combination_for $@)

  if [[ $RESULT = 0 ]] || _check_if_does_not_have_ingredients_in_pack $@; then
    _merge_help
    exit 1
  fi

  FIRST_AMOUNT=$2
  FIRST_ITEM=$3
  SECOND_AMOUNT=$4
  SECOND_ITEM=$5

  _discard $FIRST_AMOUNT $FIRST_ITEM > /dev/null
  _discard $SECOND_AMOUNT $SECOND_ITEM > /dev/null

  echo $RESULT >> $BACKPACK_FILE

  echo "You have created a new item!"
  echo
}

function _display_discard_help() {
  echo "discard [number of item to discard] [item]"
  echo "You can't discard items that you don't own"
}

function _discard() {
  if [[ $# -eq 2 ]] && (uniq $BACKPACK_FILE | grep -Fxq $2) && [[ $1 -le $(grep "^$2$" -c $BACKPACK_FILE) ]]; then
    for ((a=1; a <= $1; a++)); do
      awk "/^$2$/ { if (++f == 1) next} 1" $BACKPACK_FILE > replica.txt && mv replica.txt $BACKPACK_FILE
    done
    echo "Successfully discarded $1 $2."
    _show
  else
    _display_discard_help
    exit 1
  fi
}

if [[ ! -e $BACKPACK_FILE ]]; then
  touch $BACKPACK_FILE
  _initialize_pack
fi

if [[ $1 = 'show' ]] && [[ $# -eq 1 ]]; then
  _show
elif [[ $1 = 'search' ]] && [[ $2 ]]; then
  _search $2
elif [[ $1 = 'sort' ]] && [[ $# -eq 1 ]]; then
  _sort_pack
elif [[ $1 = 'add' ]] && [[ $2 ]]; then
  _add $2
elif [[ $1 = 'discard' ]]; then
  _discard $(echo $@ | cut -f 2-3 -d ' ' -s)
elif [[ $1 = 'merge' ]]; then
  _merge $@
elif [[ $1 = 'number_of_item_in_pack' ]]; then
  _number_of_item_in_pack $2
else
  _display_general_help
fi
