#!/usr/bin/env bash

source scripts/languages.bash

# Set up .env file if it doesn't exist
function setup_env_file() {
  echo ".env file not found. Let's create one!"

  # Prompt user for NICKNAME
  read -r -p "Enter your nickname (default: Unknown): " nickname
  nickname=${nickname:-Unknown}

  # Prompt user for LANGUAGE
  echo "Select your preferred language:"
  languages=("cpp" "java" "python" "python3" "c" "csharp" "javascript" "typescript" "php" "swift" "kotlin" "dart" "golang" "ruby" "scala" "rust" "racket" "erlang" "elixir")
  for i in "${!languages[@]}"; do
    echo "$((i + 1))) ${languages[$i]}"
  done
  read -r -p "Enter the number (default: 4): " language_index
  language_index=${language_index:-4}
  language=${languages[$((language_index - 1))]}

  # Create .env file with user input or default values
  echo "NICKNAME=$nickname" >.env
  echo "LANGUAGE=$language" >>.env

  echo ".env file created with the following values:"
  echo "NICKNAME: $nickname"
  echo "LANGUAGE: $language"
}

# Load environment variables from .env file
function load_env_vars() {
  if [ ! -f .env ]; then
    setup_env_file
  fi

  # shellcheck disable=SC2046
  export $(sed <.env 's/#.*//g' | xargs | envsubst)

  # Check if NICKNAME and LANGUAGE variables are set
  if [ -z "$NICKNAME" ] || [ -z "$LANGUAGE" ]; then
    echo "Error: Required environment variables NICKNAME and/or LANGUAGE are not set."
    echo "Please set NICKNAME and LANGUAGE in the .env file with appropriate values."
    exit 1
  fi

  # Check if the specified language is valid
  if [[ ! "${!language_extensions[@]}" =~ $LANGUAGE ]]; then
    echo "Error: Invalid language specified in the .env file."
    echo "Please set LANGUAGE to one of the following valid languages:"
    echo "${!language_extensions[@]}"
    exit 1
  fi
}

# Check if Bash version meets the minimum requirement
function check_bash_version() {
  local required_version=$1
  local bash_version
  bash_version=$(bash --version | head -n1 | awk '{print $4}' | sed 's/\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/')

  if [[ $bash_version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    local major=${BASH_REMATCH[1]}
    local minor=${BASH_REMATCH[2]}
    local patch=${BASH_REMATCH[3]}

    IFS='.' read -r -a required_parts <<<"$required_version"
    local required_major=${required_parts[0]}
    local required_minor=${required_parts[1]}
    local required_patch=${required_parts[2]}

    if ((major > required_major || (\
      major == required_major && minor > required_minor) || (\
      major == required_major && minor == required_minor && patch >= required_patch))); then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

# Check if a command is installed
function check_command() {
  local command="$1"
  if ! command -v "$command" &>/dev/null; then
    echo "The $command command is not installed."
    read -r -p "Do you want to install $command? (Y/n): " install_command
    case "$install_command" in
    [nN] | [nN][oO])
      echo "Installation of $command has been rejected. Exiting the script."
      exit 1
      ;;
    *)
      echo "Proceeding with the installation of $command..."
      brew install "$command"
      ;;
    esac
  fi
}

# Generates the solution code template with question details and author information
function make_solution_code() {
  local question_id=$1
  local question_name=$2
  local question_url=$3
  local code=$4
  local comment=${language_comments[$LANGUAGE]}
  local nickname
  if [ -n "$NICKNAME" ]; then
    nickname=$NICKNAME
  else
    nickname=Unknown
  fi
  local content
  content=$(
    cat <<EOF
${comment}
${comment}$question_id. $question_name
${comment}$question_url
${comment}Dale-Study
${comment}
${comment}Created by $nickname on $(date "+%Y/%m/%d").
${comment}

$code

EOF
  )
  echo "$content"
}

# Saves the solution code to a file in the appropriate directory based on the question slug and author's nickname
function save_file() {
  local DIR
  local title_slug="$1"
  local content="$2"
  local nickname
  local language_extension
  local solution_folder
  local solution_file

  if [ -n "$NICKNAME" ]; then
    nickname=$NICKNAME
  else
    nickname=Unknown
  fi

  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
  language_extension=${language_extensions[$LANGUAGE]}

  solution_folder="$DIR/../$title_slug"
  mkdir -p "$solution_folder"

  solution_file="$solution_folder/$nickname.$language_extension"
  echo "$content" >"$solution_file"
  echo "File creation completed"
}
