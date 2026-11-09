let nextFeeIndex = Date.now();

document.addEventListener("click", (event) => {
  document.querySelectorAll(".dropdown[open]").forEach((menu) => {
    if (!menu.contains(event.target)) menu.open = false;
  });
  const button = event.target.closest("button");
  if (!button) return;

  if (button.hasAttribute("data-add-fee")) {
    const template = document.getElementById("event-fee-template");
    const fields = template.innerHTML.replaceAll("new_event_fees", String(nextFeeIndex++));
    template.insertAdjacentHTML("beforebegin", fields);
    template.previousElementSibling.querySelector("input:not([type=hidden])").focus();
  }

  if (button.hasAttribute("data-remove-fee")) {
    button.previousElementSibling.value = "1";
    button.closest(".fields").hidden = true;
    document.querySelector("[data-add-fee]").focus();
  }

  if (button.dataset.openDialog) {
    document.getElementById(button.dataset.openDialog).showModal();
  }

  if (button.hasAttribute("data-close-dialog")) {
    button.closest("dialog").close();
  }

  if (button.hasAttribute("data-history-back")) {
    history.back();
  }
});

document.addEventListener("keydown", (event) => {
  if (event.key !== "Escape") return;
  const menu = event.target.closest(".dropdown[open]");
  if (!menu) return;

  menu.open = false;
  menu.querySelector("summary").focus();
});

document.addEventListener("submit", async (event) => {
  const form = event.target;
  if (form.dataset.confirm && !window.confirm(form.dataset.confirm)) {
    event.preventDefault();
    return;
  }
  if (!form.hasAttribute("data-update-fees")) return;

  event.preventDefault();
  const status = form.querySelector("[role=status]");
  const submitter = event.submitter;
  if (submitter) submitter.disabled = true;
  status.textContent = "";
  try {
    const response = await fetch(form.action, {
      method: form.method,
      body: new FormData(form),
      headers: { "Accept": "text/html", "X-Requested-With": "XMLHttpRequest" }
    });
    if (response.redirected) {
      window.location.assign(response.url);
      return;
    }
    if (!response.ok) throw new Error("受付情報の更新に失敗しました。");

    document.getElementById("entry_fees_table").innerHTML = await response.text();
    status.textContent = "受付情報を更新しました。";
  } catch {
    status.textContent = "受付情報を更新できませんでした。もう一度お試しください。";
  } finally {
    if (submitter) submitter.disabled = false;
  }
});

const entriesTable = document.getElementById("myTable");
if (entriesTable) {
  const headers = Array.from(entriesTable.tHead.rows[0].cells);
  const body = entriesTable.tBodies[0];
  const collator = new Intl.Collator("ja", { numeric: true, sensitivity: "base" });

  headers.forEach((header, index) => {
    if (index === 0) return;
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = header.textContent.trim();
    header.replaceChildren(button);
    button.addEventListener("click", () => {
      const descending = header.getAttribute("aria-sort") === "ascending";
      headers.forEach((cell) => cell.removeAttribute("aria-sort"));
      header.setAttribute("aria-sort", descending ? "descending" : "ascending");
      const rows = Array.from(body.rows).sort((a, b) => {
        const aCell = a.cells[index];
        const bCell = b.cells[index];
        const aValue = aCell.dataset.sortValue ?? aCell.textContent.trim();
        const bValue = bCell.dataset.sortValue ?? bCell.textContent.trim();
        return collator.compare(aValue, bValue) * (descending ? -1 : 1);
      });
      body.append(...rows);
    });
  });
}
