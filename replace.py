import os
import re

import_stmt = "import 'package:nexus/core/utils/currency_formatter.dart';\n"
pattern = re.compile(r"₹\$\{([a-zA-Z0-9_\.\(\)\? \!]+)\.toStringAsFixed\([02]\)\}")

for root, dirs, files in os.walk("lib"):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            with open(path, "r") as f:
                content = f.read()
            
            if pattern.search(content):
                # Replace pattern
                new_content = pattern.sub(r"₹${\1.toAppCurrency()}", content)
                
                # Check if import is already there
                if "currency_formatter.dart" not in new_content:
                    # Find last import to insert after it, or insert at top
                    lines = new_content.splitlines(True)
                    last_import_idx = -1
                    for i, line in enumerate(lines):
                        if line.startswith("import "):
                            last_import_idx = i
                    
                    if last_import_idx != -1:
                        lines.insert(last_import_idx + 1, import_stmt)
                    else:
                        lines.insert(0, import_stmt)
                    
                    new_content = "".join(lines)
                
                with open(path, "w") as f:
                    f.write(new_content)
                print(f"Updated {path}")
