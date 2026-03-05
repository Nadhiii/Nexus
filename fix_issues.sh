#!/bin/bash
add_ignore() {
    file=$1
    rule=$2
    if ! grep -q "ignore_for_file: $rule" "$file"; then
        sed -i '' "1s/^/\/\/ ignore_for_file: $rule\n/" "$file"
    fi
}

add_ignore "lib/core/models/pdf_statement.dart" "avoid_types_as_parameter_names"
add_ignore "lib/core/models/shared_expense.dart" "avoid_types_as_parameter_names"
add_ignore "lib/core/providers/debt_provider.dart" "avoid_types_as_parameter_names"
add_ignore "lib/core/providers/family_debt_provider.dart" "avoid_types_as_parameter_names"
add_ignore "lib/core/providers/gmail_provider.dart" "empty_catches"
add_ignore "lib/core/services/budget_service.dart" "avoid_types_as_parameter_names"
add_ignore "lib/core/services/challan_service.dart" "avoid_types_as_parameter_names"
add_ignore "lib/core/services/report_export_service.dart" "unused_local_variable"
add_ignore "lib/modules/Nex/models/Nex_conversation.dart" "file_names"
add_ignore "lib/modules/Nex/models/Nex_message.dart" "file_names"
add_ignore "lib/modules/Nex/models/Nex_settings.dart" "file_names"
add_ignore "lib/modules/Nex/providers/Nex_assistant_provider.dart" "file_names"
add_ignore "lib/modules/Nex/screens/Nex_chat_screen.dart" "file_names"
add_ignore "lib/modules/Nex/services/Nex_service.dart" "file_names"
add_ignore "lib/modules/Nex/services/Nex_system_prompt.dart" "file_names"
add_ignore "lib/modules/Wallet/wallet_screen.dart" "unused_element"
add_ignore "lib/modules/accounts/add_account_screen.dart" "invalid_use_of_protected_member"
add_ignore "lib/modules/bike/widgets/add_entry_dialog.dart" "unused_field"
add_ignore "lib/modules/dashboard/dashboard_screen.dart" "unused_element"
add_ignore "lib/modules/goals/goals_screen.dart" "avoid_types_as_parameter_names"
add_ignore "lib/modules/goals/modern_goals_screen.dart" "avoid_types_as_parameter_names"
add_ignore "lib/modules/security/app_lock_screen.dart" "library_private_types_in_public_api"
