dir="$(dirname "${BASH_SOURCE[0]}")"
for f in "${dir}/bash_completion.d/"*sh; do
    # shellcheck disable=SC1090
    source "${f}"
done
