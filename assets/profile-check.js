const select = document.querySelector("#person-select");
const result = document.querySelector("#profile-result");
const loading = document.querySelector("#loading");

const escapeHtml = (value = "") => String(value)
  .replaceAll("&", "&amp;")
  .replaceAll("<", "&lt;")
  .replaceAll(">", "&gt;")
  .replaceAll('"', "&quot;")
  .replaceAll("'", "&#039;");

const safeUrl = (value = "") => {
  try {
    const url = new URL(value);
    return ["http:", "https:"].includes(url.protocol) ? url.href : "";
  } catch {
    return "";
  }
};

const externalLink = (url, label) => {
  const safe = safeUrl(url);
  return safe ? `<a href="${escapeHtml(safe)}" target="_blank" rel="noopener">${escapeHtml(label)}</a>` : "";
};

const empty = (message) => `<p class="empty">${escapeHtml(message)}</p>`;

const renderPublications = (items) => {
  if (!items?.length) return empty("No recent publications were returned by ORCID or Scholar for this snapshot.");
  return `<ul class="publications">${items.map((item) => {
    const title = item.url ? externalLink(item.url, item.title) : escapeHtml(item.title);
    const journal = item.journal ? ` <span class="journal">${escapeHtml(item.journal)}</span>` : "";
    return `<li><span class="year">${escapeHtml(item.year || "n.d.")}</span> ${title}.${journal}</li>`;
  }).join("")}</ul>`;
};

const renderItems = (items) => {
  if (!items?.length) return empty("No projects, activities, media or prizes were visible in the profile snapshot.");
  return `<ul>${items.map((item) => {
    const title = item.url ? externalLink(item.url, item.title) : escapeHtml(item.title);
    return `<li><span class="item-type">${escapeHtml(item.type)}</span><br>${title}${item.details ? ` — ${escapeHtml(item.details)}` : ""}</li>`;
  }).join("")}</ul>`;
};

const renderPerson = (person) => {
  const profileLink = externalLink(person.profile_url, "Open Monash profile");
  const orcidLink = externalLink(person.orcid_url, "Open ORCID");
  const scholarLink = externalLink(person.scholar_url, "Open Google Scholar");
  const keywords = person.research_keywords?.length
    ? `<div class="tag-list">${person.research_keywords.map((word) => `<span class="tag">${escapeHtml(word)}</span>`).join("")}</div>`
    : empty("No research keywords were returned by the Monash profile.");
  const identityWarnings = [];
  if (!person.orcid_url) identityWarnings.push("No ORCID was recorded in the Hub roster.");
  if (!person.scholar_url) identityWarnings.push("No Google Scholar profile was recorded in the Hub roster.");

  result.innerHTML = `
    <div class="profile-header">
      <h2>${escapeHtml(person.name)}</h2>
      <div class="profile-meta">${escapeHtml([person.role, person.organisation].filter(Boolean).join(" · ") || "No role or organisation returned")}</div>
      <div class="source-date">Monash profile retrieved ${escapeHtml(person.profile_retrieved || "date unavailable")}; publication snapshot ${escapeHtml(person.publications_retrieved || "date unavailable")}.</div>
      <div class="link-row">${profileLink}${orcidLink}${scholarLink}</div>
    </div>
    <div class="evidence-grid">
      ${identityWarnings.length ? `<section class="evidence-card warning"><h3>Identifier check</h3><ul>${identityWarnings.map((x) => `<li>${escapeHtml(x)}</li>`).join("")}</ul></section>` : ""}
      <section class="evidence-card">
        <h3>Research keywords</h3>
        ${keywords}
      </section>
      <section class="evidence-card wide">
        <h3>Biography currently visible</h3>
        ${person.biography ? `<div class="biography">${escapeHtml(person.biography)}</div>` : empty("No biography was returned by the Monash profile.")}
      </section>
      <section class="evidence-card wide">
        <h3>Recent publications returned</h3>
        ${renderPublications(person.publications)}
      </section>
      <section class="evidence-card wide">
        <h3>Other visible profile items</h3>
        ${renderItems(person.profile_items)}
      </section>
    </div>`;
  result.hidden = false;
};

fetch("data/people.json")
  .then((response) => {
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.json();
  })
  .then((data) => {
    loading.remove();
    const people = data.people || [];
    people.forEach((person, index) => {
      const option = document.createElement("option");
      option.value = String(index);
      option.textContent = person.name;
      select.append(option);
    });
    select.addEventListener("change", () => {
      if (select.value === "") {
        result.hidden = true;
        result.innerHTML = "";
        return;
      }
      renderPerson(people[Number(select.value)]);
    });
    const requestedName = new URLSearchParams(window.location.search).get("person");
    const requestedIndex = people.findIndex((person) => person.name.toLowerCase() === requestedName?.toLowerCase());
    if (requestedIndex >= 0) {
      select.value = String(requestedIndex);
      renderPerson(people[requestedIndex]);
    }
  })
  .catch((error) => {
    loading.textContent = `The corpus snapshot could not be loaded (${error.message}).`;
  });

