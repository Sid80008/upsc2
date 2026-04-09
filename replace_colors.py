import os

files = [
    r'c:\Users\siddh\OneDrive\Desktop\CODES\Projects\UPSC\mobile_app\upsc_app\lib\screens\report_screen.dart',
    r'c:\Users\siddh\OneDrive\Desktop\CODES\Projects\UPSC\mobile_app\upsc_app\lib\screens\premium_insights_screen.dart'
]

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    content = content.replace('Colors.emerald', 'Colors.teal')
    content = content.replace('Colors.rose', 'Colors.pink')
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)
print("Done replacing colors")
