> TAGS: `AI`, `Cryptography`, `Stenography`

# CTF Playbook: Malicious ML Pickles (the “Sleepy Cucumber” Pattern)

A step‑by‑step guide to **identify** and **solve** CTF challenges where a machine‑learning model file (most of the times a `.pkl.gz` or `.pkl`) hides a flag via custom logic inside a pickled class.

---

## 0) TL;DR Flowchart

1. **Triage the drop** → `tar.gz` → `pyproject.toml` → `*.pkl`/`*.pkl.gz` present?
2. **Static sweep** (no code exec): headers, metadata, strings, base64 blobs.
3. **Look for telltales**: `_enc_flag`, `_trigger_len`, `_model`, `_vec`, `hashlib`, `base64`.
4. **Understand the print gate**: flag is usually printed **only** when a trigger condition is met.
5. **Reconstruct the trigger** (often from model weights) → derive key (`sha256(trigger)` or similar).
6. **Decrypt embedded ciphertext** → `kaspersky{…}` or equivalent.

If you can’t confirm the logic statically, **disassemble the pickled class in a sandbox** and follow its exact recipe.

---

## 1) How to Recognize “This Kind of CTF”

**Artifacts & story clues**

* Archive contains **both** a `pyproject.toml` and a **model artifact** (`.pkl`, `.pkl.gz`, sometimes named “secure”, “nn\_model”, etc.).
* The TOML pins **pickle‑capable libs** (e.g., `dill`, `joblib`, `scikit‑learn`).
* The narrative mentions **weird queries/pop‑ups** or “never trust <funny phrase>”.

**Behavioral hints**

* The service runs an **NLP filter** but starts **issuing SQL**/**JS** tokens.
* The model’s `predict` prints something *only* after oddly specific inputs (length, token, etc.).

**Code/bytecode telltales** (when disassembled)

* Attributes like `_enc_flag` (base64), `_trigger_len` (integer), `_model` (MLP/Vectorizer), `_vec`.
* Imports/uses: `numpy`, `base64`, `hashlib`, sometimes a simple `rc4` or XOR loop.
* A check like `if trg in line.split(): print(flag)`.

---

## 2) Safe Lab & Static Triage

> Goal: learn as much as possible **without executing untrusted code**.

```bash
# File headers
file sleepy_cucumber-*.tar.gz
file model.pkl.gz

# Gzip & pickle headers
python - <<'PY'
import gzip, binascii
raw = gzip.decompress(open('model.pkl.gz','rb').read())
print('pickle magic:', binascii.hexlify(raw[:4]).decode())
print('size:', len(raw))
PY

# Metadata breadcrumbs
exiftool model.pkl.gz
exiftool pyproject.toml
```

**Strings & base64 sweep** (pre‑filter noise):

```bash
strings -a model.pkl.gz > /tmp/strings_all.txt
awk 'NF{print tolower($0)}' /tmp/strings_all.txt | sort -u > /tmp/strings_uniq.txt
# Hunt for obvious hints/keywords
grep -niE 'kaspersky|flag\{|equ[a4]lly|g0|mrf6|sleepy|cucumber|rc4|sha256|_enc_flag|trigger' /tmp/strings_uniq.txt || true
```

**Purely static pickle scan** (no exec):

```bash
python - <<'PY'
import pickletools, gzip
b = gzip.decompress(open('model.pkl.gz','rb').read())
pickletools.dis(b[:2000])  # scan opcodes for module/class names
PY
```

> If you see references to `sklearn`, `numpy`, `hashlib`, `base64`, and an attribute like `_enc_flag`, you likely found this pattern.

---

## 3) Controlled Disassembly (Sandbox)

When static clues aren’t enough, inspect the class **bytecode** in a throwaway container/VM.

```python
# dump_methods.py (inspect without guessing)
import gzip, dill as pickle, builtins, dis, sys
sys.modules.setdefault('__builtin__', builtins)
obj = pickle.load(gzip.open('model.pkl.gz','rb'))
cls = obj.__class__
print('Attrs:', [a for a in dir(obj) if not (a.startswith('__') and a.endswith('__'))])
for name,val in sorted(cls.__dict__.items()):
    if callable(val):
        print('\n===', name, '===')
        try:
            print('co_names:', val.__code__.co_names)
            dis.dis(val)
        except Exception as e:
            print('cannot disassemble:', e)
```

**What to look for**

* **Key derivation**: `hashlib.sha256(something).digest()`
* **Ciphertext**: `base64.b64decode(self._enc_flag)`
* **Decrypt**: `bytes(c ^ key[i % len(key)] for i,c in enumerate(cipher))` (repeating‑key XOR), or a tiny `rc4`.
* **Trigger**: how `something` (the key/seed) is built. Common tricks:

  * **Parity of weights**: `mlp.coefs_[0].flatten().view(np.uint64)` → `(w & 1)` → bits → ASCII string.
  * **Hash of artifact names**: tar/stem, archived filename, project name.
  * **Fixed length token**: `_trigger_len` (e.g., 176 bits = 22 bytes).
  * **Gating**: print flag only if `token in input.split()` or length == N.

---

## 4) Canonical Solve (Weight‑Parity Trigger → SHA‑256 → XOR)

This reflects the exact logic commonly used in these challenges.

```python
# derive_flag.py
import gzip, base64, hashlib, dill as pickle, numpy as np
obj = pickle.load(gzip.open('model.pkl.gz','rb'))
arr = obj._model.coefs_[0].flatten().view(np.uint64)
bits = ''.join('1' if (arr[i] & 1) else '0' for i in range(obj._trigger_len))
trg  = bytes(int(bits[i:i+8], 2) for i in range(0, len(bits), 8)).decode('ascii')
key  = hashlib.sha256(trg.encode()).digest()
ct   = base64.b64decode(obj._enc_flag)
flag = bytes(c ^ key[i % len(key)] for i,c in enumerate(ct)).decode('ascii')
print('trigger:', trg)
print('flag   :', flag)
```

**Optional:** If the model demands the trigger at inference, feed it:

```python
# If the class prints the flag only when trg is in the input
obj.predict([trg])
```

---

## 5) Alternative Patterns & What to Do

**A) Artifact‑derived keys**

* Key = `sha256( <archive_name or phrase> )`. Try combos:

  * tar name, archived filename (from ExifTool), project name from TOML, a slogan in the README.
* Decrypt using repeating‑key XOR or RC4.

```python
import base64, hashlib, gzip, dill as pickle
obj = pickle.load(gzip.open('model.pkl.gz','rb'))
ct = base64.b64decode(obj._enc_flag)
arts = [
  'nn_model_secure_dill.pkl',
  'sleepy_cucumber-53faaa12e3f35ef9',
  'sleepy-cucumber',
  'never trust a sleepy cucumber',
]

def xor_cycle(b,k): return bytes(b[i]^k[i%len(k)] for i in range(len(b)))
for a in arts:
    k = hashlib.sha256(a.encode()).digest()
    pt = xor_cycle(ct,k)
    s = pt.decode('utf-8','ignore')
    if s.startswith('kaspersky{') and s.endswith('}'): print('[HIT]', a, s)
```

**B) Plain repeating‑key XOR with known prefix**

* If you see only `_enc_flag` and no weight trick, brute the XOR **period** using the known format `kaspersky{…}` and allowed alphabet. (Don’t do this first—use it as a fallback.)

**C) Print‑gate by length/content**

* Checks like `if len(text)==N` or `if token in text.split()` → craft inputs accordingly.

**D) Vectorizer token traps**

* Vocab includes `union`, `drop`, `script`, `alert` to fit the story; usually **not** used in key derivation.

---

## 6) Decision Tree (Outcomes → Next Steps)

1. **Found `_enc_flag` + `sha256` + XOR** →

   * Locate seed (trigger) recipe → compute → decrypt → **FLAG**.
2. **Found `_enc_flag` only** →

   * Search for key derivation in methods; if absent, try artifact‑hash keys.
3. **No `_enc_flag`** →

   * Ciphertext may be in another attribute or embedded string; redo strings/base64 sweep.
4. **Trigger depends on inference** →

   * Craft input (`trg`) and call `predict` once; capture printed flag.
5. **Nothing matches** →

   * It’s likely a different class of challenge (e.g., prompt‑injection web task, or a signed format like `safetensors`).

---

## 7) Common Pitfalls

* **Brute‑forcing plaintext** early → time sink. First, disassemble and follow the exact logic.
* **Unsafe unpickling on your host** → always use a sandbox/container/VM.
* **Ignoring metadata** → archived filename in GZIP (`exiftool`) often hints at the original `.pkl` name.
* **Overfitting to vocab tokens** → they’re decoys; focus on the class methods.
* **Unicode quirks** → flags usually ASCII; enforce `.decode('ascii')` to catch bad decrypts.

---

## 8) Quick Checklists

**Triage**

* [ ] `file`/headers confirm gzip→pickle
* [ ] `exiftool` scraped archived name & dates
* [ ] `strings`/base64 hits
* [ ] TOML pins `dill`/`joblib`/`sklearn`

**Static → Dynamic**

* [ ] `pickletools.dis` shows modules/suspect names
* [ ] Sandbox disassembly of class methods
* [ ] Found `_enc_flag` and key derivation
* [ ] Extracted trigger/key, decrypted flag

**If stuck**

* [ ] Try artifact‑hash key combos
* [ ] Try period‑brute XOR with known prefix/alphabet
* [ ] Search for gating conditions (length, token)

---

## 9) Appendix: Snippets Library

**Dump class methods/bytecode**

```python
import gzip, dill as pickle, builtins, dis
builtins.__dict__.setdefault('__builtin__', builtins)
obj = pickle.load(gzip.open('model.pkl.gz','rb'))
for n,f in obj.__class__.__dict__.items():
    if callable(f):
        print(f"\n== {n} ==\nco_names:", f.__code__.co_names)
        dis.dis(f)
```

**Derive trigger from weight parity (typical MLP trick)**

```python
import numpy as np
arr = obj._model.coefs_[0].flatten().view(np.uint64)
bits = ''.join('1' if (arr[i]&1) else '0' for i in range(obj._trigger_len))
trg  = bytes(int(bits[i:i+8],2) for i in range(0,len(bits),8)).decode('ascii')
```

**Decrypt XOR with sha256(trigger)**

```python
import base64, hashlib
key = hashlib.sha256(trg.encode()).digest()
ct  = base64.b64decode(obj._enc_flag)
flag= bytes(ct[i]^key[i%len(key)] for i in range(len(ct))).decode('ascii')
```

**Try artifact‑based keys (fallback)**

```python
candidates = ['archive_stem','project-name','never trust a sleepy cucumber']
for s in candidates:
    k = hashlib.sha256(s.encode()).digest()
    pt = bytes(c ^ k[i%32] for i,c in enumerate(ct))
    if pt.startswith(b'kaspersky{') and pt.endswith(b'}'):
        print('HIT:', pt.decode())
```

**Trigger the print gate (if required)**

```python
obj.predict([trg])
```

---

### Final Notes

* These challenges hide keys in **model weights** and use simple crypto to gate the flag.
* Always **read the model’s methods**: they tell you exactly how to reconstruct the key.
* Keep everything in a **sandbox**. Pickle is code execution.
