#!/usr/bin/env python3
import sys
import os
import argparse
from google import genai
from google.genai import types
from rich.console import Console
from rich.markdown import Markdown

LOG_FILE = "/tmp/clicom_monitor.log"
console = Console()

# VPN Support
proxy_vars = ['http_proxy', 'https_proxy', 'HTTP_PROXY', 'HTTPS_PROXY', 'all_proxy', 'ALL_PROXY']
for key in proxy_vars:
    val = os.environ.get(key)
    if val and val.startswith('socks://'):
        os.environ[key] = val.replace('socks://', 'socks5://')

def get_gemini_response(prompt, mode="command", model_name="gemini-3-flash-preview"):
    api_key = os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        sys.stderr.write("\033[91mError: GOOGLE_API_KEY not set.\033[0m\n")
        sys.exit(1)

    try:
        client = genai.Client(api_key=api_key)
        
        if mode == "explain":
            sys_instruction = (
                "You are a concise Linux terminal expert. "
                "Analyze logs and provide a punchy explanation. "
                "Use Markdown. Always warn about leaked keys in logs."
            )
        elif mode == "opinion":
            sys_instruction = (
                "You are a Linux system analyst. "
                "Review the provided command output and the user's original intent. "
                "Provide a short, expert opinion/analysis on the results. "
                "Use Markdown for formatting."
            )
        else:
            sys_instruction = (
                "You are a CLI command generator. "
                "Convert request to a single Shell command. "
                "Output ONLY the raw command. No markdown, no explanations."
            )

        response = client.models.generate_content(
            model=model_name,
            contents=prompt,
            config=types.GenerateContentConfig(
                system_instruction=sys_instruction,
                temperature=0.7 if mode != "command" else 0.1
            )
        )
        
        final_text = ""
        if response.candidates and response.candidates[0].content.parts:
            for part in response.candidates[0].content.parts:
                if part.text: final_text += part.text
        return final_text.strip()

    except Exception as e:
        sys.stderr.write(f"\n\033[91mAPI Error: {e}\033[0m\n")
        sys.exit(1)

def read_log_tail(filepath):
    if not os.path.exists(filepath): return None
    try:
        file_size = os.path.getsize(filepath)
        with open(filepath, 'rb') as f:
            if file_size > 32768: f.seek(-32768, 2)
            return f.read().decode('utf-8', errors='ignore')
    except: return None

def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("query", nargs="*", default=[])
    parser.add_argument("-fix", action="store_true")
    parser.add_argument("-h", "--history", action="store_true")
    parser.add_argument("-wtf", action="store_true")
    parser.add_argument("-opinion", type=str, default=None) # New mode for analysis
    parser.add_argument("-model", type=str, default="gemini-3-flash-preview")
    
    args = parser.parse_args()
    user_query = " ".join(args.query)
    
    if not user_query and not args.fix and not args.history and not args.opinion:
        sys.exit(0)

    if args.opinion:
        # Opinion mode: analyze provided output
        prompt = f"User Intent: {user_query}\n\nCommand Output to analyze:\n{args.opinion}"
        result = get_gemini_response(prompt, "opinion", args.model)
        console.print(Markdown(result))
        sys.exit(0)

    context_data = ""
    if args.fix or args.wtf:
        log_data = read_log_tail(LOG_FILE)
        if log_data: context_data += f"\n=== TERMINAL LOG ===\n{log_data}\n"

    if args.history or args.fix:
        if not sys.stdin.isatty():
            context_data += f"\n=== HISTORY ===\n{sys.stdin.read().strip()}\n"

    full_prompt = f"{context_data}\n\nUser Request: {user_query}"
    if args.fix and not user_query: full_prompt += "Fix the error shown in the logs."

    sys.stderr.write("\033[90mGenAI thinking...\033[0m\r")
    sys.stderr.flush()

    mode = "explain" if args.wtf else "command"
    result = get_gemini_response(full_prompt, mode, args.model)
    sys.stderr.write("                 \r")

    if mode == "explain":
        console.print(Markdown(result))
    else:
        clean_cmd = result.replace("```bash", "").replace("```sh", "").replace("```", "").split("\n")[0].strip()
        print(clean_cmd)

if __name__ == "__main__":
    main()