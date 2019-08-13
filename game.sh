#!/usr/local/bin/bash

ALL_ROOMS=.all_rooms.txt
GAME_STATE=.game_state.txt
MAP_FILE=.map.txt

function _display_general_help() {
  echo "Here are the following commands"
  echo "* goto [room]"
  echo "* profile"
  echo "* map"
  echo "* search_current_room"
  echo
  exit 1
}

function _display_goto_help() {
  echo "game.sh goto [room in house]"
  echo "Note that the room needs to exist in the house"
  echo
  exit 1
}

_goto() {
  # Create or write to existing file all house names
  find .house -type f -exec basename {} ".txt" ";" > $ALL_ROOMS
  if [[ ! $# -eq 2 ]] || ! grep -Fxq "$2" $ALL_ROOMS; then
    _display_goto_help
  fi

  FILE_NAME="$2.txt"
  FILE_LOCATION=$(find .house -name $FILE_NAME)

  _change_current_location $2

  if [[ ! -s $FILE_LOCATION ]]; then
    echo "You found nothing in the $2."
    echo
  else
    echo "After some rummaging, you've found the following items in the $2:"
    cat $(find .house -name $FILE_NAME)
  fi
}

_map() {
  NUMBER_OF_LADDERS_IN_PACK=$(./backpack.sh number_of_item_in_pack ladder)
  if [[ $NUMBER_OF_LADDERS_IN_PACK -ge 1 ]]; then
    cat $MAP_FILE
  else
    tail -n +23 $MAP_FILE
  fi
}

_search_current_room() {
  CURRENT_ROOM=$(sed -E "s/^\* Current location: (.*)/\1/g" $GAME_STATE)
  ROOM_FILE=$(find .house -name "$CURRENT_ROOM.txt")

  echo "After some rummaging..."
  if [[ -s $ROOM_FILE ]]; then
    echo "You find the following items"
    cat $ROOM_FILE
  else
    echo "There is nothing to be found in the $CURRENT_ROOM."
  fi
}

_change_current_location() {
  # change the game state to have the same format but just changed name
  sed -i '' -E "s/(^\* Current location:).*/\1 $1/g" $GAME_STATE
  echo "Travelling to the new location..."
}

_profile() {
  echo "Hello $(whoami), here is your profile:"
  cat $GAME_STATE
  echo
}

_initialize_game_state() {
  touch $GAME_STATE
  echo "* Current Location: living_room" >> $GAME_STATE
}

if [[ ! -e $GAME_STATE ]]; then
  _initialize_game_state
fi

if [[ $1 = 'goto' ]]; then
  _goto $@
elif [[ $1 = 'profile' ]]; then
  _profile
elif [[ $1 = 'map' ]]; then
  _map
elif [[ $1 = 'search_current_room' ]]; then
  _search_current_room
else
  _display_general_help
fi
