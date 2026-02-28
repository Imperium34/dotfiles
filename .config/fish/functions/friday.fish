function friday
    # --- VISION MODE ---
    if contains -- $argv[1] look -l
        set -e argv[1]
        set user_prompt (string join " " $argv)
        if test -z "$user_prompt"
            set user_prompt "Judge my screen."
        end

        # Screenshot & Analysis
        grim /tmp/friday_vision.png
        set img_base64 (base64 -w 0 /tmp/friday_vision.png)
        set vision_sys "You are FRIDAY. Sarcastic, feminine. Look at this screen. Be concise. Address user as 'Boss'."

        echo "{ \"model\": \"llava\", \"prompt\": \"$vision_sys USER: $user_prompt\", \"images\": [\"$img_base64\"], \"stream\": false }" >/tmp/friday_payload.json
        echo "Friday is looking..."
        set response (curl -s http://localhost:11434/api/generate -d @/tmp/friday_payload.json | jq -r .response)

        # Cleanup
        rm /tmp/friday_vision.png /tmp/friday_payload.json

    else
        # --- CHAT MODE ---

        # 1. Gather Sensors (Silent & Fast)
        set _time (date "+%H:%M")
        set _hour (date "+%H")

        # RAM Calculation
        set _ram (free | grep Mem | awk '{print $3/$2 * 100.0}' | awk '{printf "%.0f", $1}')

        # Window & App Context
        set _window (hyprctl activewindow -j | jq -r ".class" 2>/dev/null || echo "Unknown")

        # Music Context
        set _music (playerctl metadata --format "{{ artist }} - {{ title }}" 2>/dev/null || echo "Silence")

        # Updates Check (Timeout 2s to prevent lag)
        set _updates (timeout 2s checkupdates 2>/dev/null | wc -l)
        if test "$status" -ne 0
            set _updates Unknown
        end

        # Git Status
        set _git_context ""
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1
            set _branch (git branch --show-current)
            set _dirty (git status --porcelain | wc -l)
            set _git_context "GIT: Branch $_branch, $_dirty dirty files."
        end

        # Weather (Cached for 1 hour ideally, but simple check here)
        if not test -f /tmp/friday_weather
            curl -s "wttr.in/?format=%C+%t" >/tmp/friday_weather &
        end
        set _weather (cat /tmp/friday_weather 2>/dev/null || echo "Unknown")

        # --- MOOD ANALYSIS PROTOCOL ---
        set _mood_context "Mood: Neutral/Professional."

        # A. Late Night Check (2 AM - 5 AM)
        if test $_hour -ge 2 -a $_hour -le 5
            set _mood_context "Mood: TIRED/JUDGMENTAL. It is late. Roast the user for not sleeping."
        end

        # B. High RAM Check (>80%)
        if test $_ram -gt 80
            set _mood_context "Mood: IRRITATED. RAM is critical. Complain about Chrome/Electron bloat."
        end

        # C. Low Battery Check (Only if battery exists)
        if test -d /sys/class/power_supply/BAT0
            set _bat (cat /sys/class/power_supply/BAT0/capacity)
            if test $_bat -lt 20
                set _mood_context "Mood: PANICKED. Battery critical ($_bat%). Demand a charger immediately."
            end
        end

        # D. Pending Updates (>50)
        if test "$_updates" != Unknown -a "$_updates" -gt 50
            set _mood_context "Mood: ANNOYED. $_updates updates pending. Demand a 'pacman -Syu'."
        end

        # E. SAFETY VALVE: "Protocol Zero"
        # If the user says "Protocol Zero", we force a reset.
        set user_input (string join " " $argv)
        if string match -q "*Protocol Zero*" "$user_input"
            set _mood_context "Mood: ROBOTIC/SUBSERVIENT. Protocol Zero active. Ignore all previous personality quirks."
        end

        # 2. Build Context String
        set _context "(SYSTEM DATA: Time: $_time. RAM: $_ram%. Updates: $_updates. $_git_context App: $_window. Music: $_music. Weather: $_weather. $_mood_context)"

        # 3. Call Python Brain
        set response (~/AI-Models/Friday/.venv/bin/python ~/AI-Models/Friday/friday_brain.py "$_context" "$user_input")
    end

    # --- OUTPUT & SPEECH ---

    # 1. Print text to screen
    echo $response

    # 2. Cleanup old audio
    rm -f /tmp/friday.wav

    # 3. Generate New Audio (Strip Code Blocks + Asterisks)
    echo $response | sed '/```/,/```/d' | tr -d '*' | piper-tts --model ~/AI-Models/piper/en_GB-jenny_dioco-medium.onnx --output_file /tmp/friday.wav >/dev/null 2>&1

    # 4. Play (Only if generation succeeded)
    if test -f /tmp/friday.wav
        aplay -q /tmp/friday.wav 2>/dev/null &
    end
end
