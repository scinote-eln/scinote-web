json.id repository.id
json.name sanitize_input(repository.name)
json.shared_with_team repository.shared_with?(current_team)
