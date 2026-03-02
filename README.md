# HousingAverageCalculator

A server-side implementation of a real estate data aggregator. Built using Bash and the Common Gateway Interface (CGI), the system facilitates user registration, session-based search execution, and automated data scraping from OLX.ro.

---

## Technical Architecture

The application operates on a standard **CGI-BIN** architecture, where the web server (Apache/Nginx) executes shell scripts to process HTTP requests and interface with a MySQL backend.

### Core Stack
- **Interpreter:** Bash
- **Web Interface:** CGI (Common Gateway Interface)
- **Database:** MySQL/MariaDB
- **Protocol Handling:** `curl` for HTTP GET/POST operations
- **Data Transformation:** `grep` (PCRE), `sed`, `awk`, `tr`



---

## Component Logic

### 1. Account Management (`register.sh`)
- **Input Handling:** Parses `POST` data from `stdin` to extract `username` and `password`.
- **Validation:** - Enforces a minimum of 6 characters for usernames.
    - Enforces a minimum of 8 characters for passwords.
- **Persistence:** Performs a lookup to prevent duplicate usernames before executing an `INSERT` statement into the `LoginInfo` table.

### 2. Session Dashboard (`search.sh`)
- **Authorization:** Validates the `id` parameter against the database to ensure requests are authenticated.
- **Analytics:** - Aggregates the top 3 most searched locations via `COUNT()` and `GROUP BY`.
    - Displays the 3 most recent search results for the current environment.

### 3. Extraction Engine (`searchdata.sh`)
- **URL Normalization:** Converts user input into URL-compliant strings for the OLX directory structure.
- **Data Scraping:** - Programmatically determines total result counts and pagination depth.
    - Uses Perl-Compatible Regular Expressions (PCRE) to isolate price nodes within the HTML source.
- **Arithmetic Processing:** Calculates the arithmetic mean of gathered prices, accounting for custom sample sizes (clamped at 1,000).

---

## Database Schema

The implementation requires a MySQL database named `db` with the following structure:

### Table: `LoginInfo`
| Column | Type | Constraints |
| :--- | :--- | :--- |
| `ID` | INT | Primary Key, Auto-increment |
| `Username` | VARCHAR | Unique, Min 6 chars |
| `Password` | VARCHAR | Min 8 chars |

### Table: `Searches`
| Column | Type | Description |
| :--- | :--- | :--- |
| `Location` | VARCHAR | Normalized location string |
| `Housing` | VARCHAR | Category (Houses/Apartments) |
| `User` | INT | Foreign key to `LoginInfo.ID` |
| `Average` | INT | Computed mean price |
| `Pool` | INT | Number of listings analyzed |

---

## Deployment Configuration

1. **CGI Setup:** Enable `mod_cgi` on the host web server.
2. **Execution Bits:** Ensure all `.sh` files are set to `755` permissions.
3. **Dependencies:** Requires `mysql-client`, `curl`, and GNU coreutils (`awk`, `sed`, `grep`).

---

## Technical Disclaimer
The scraping module is highly coupled with the OLX.ro DOM structure. Changes to the target site's CSS selectors or HTML hierarchy will require updates to the `grep` patterns in `searchdata.sh`.
