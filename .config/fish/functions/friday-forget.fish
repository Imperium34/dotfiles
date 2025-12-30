function friday-forget --wraps='rm ~/.cache/friday_history.json && echo "Friday: Memory format complete."' --description 'alias friday-forget=rm ~/.cache/friday_history.json && echo "Friday: Memory format complete."'
    rm ~/.cache/friday_history.json && echo "Friday: Memory format complete." $argv
end
