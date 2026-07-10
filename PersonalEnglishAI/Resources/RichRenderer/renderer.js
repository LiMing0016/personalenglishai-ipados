(function () {
  const bridgeName = "richContent";
  const content = document.getElementById("content");
  const markdown = window.markdownit({
    html: false,
    linkify: true,
    typographer: true,
    breaks: true
  });

  if (window.mermaid) {
    window.mermaid.initialize({
      startOnLoad: false,
      securityLevel: "strict",
      theme: "default"
    });
  }

  function post(event) {
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers[bridgeName]) {
      window.webkit.messageHandlers[bridgeName].postMessage(event);
    }
  }

  function reportHeight() {
    window.requestAnimationFrame(function () {
      post({
        type: "heightChanged",
        height: Math.ceil(document.documentElement.scrollHeight)
      });
    });
  }

  function sanitize(html) {
    return window.DOMPurify.sanitize(html, {
      USE_PROFILES: { html: true },
      ADD_ATTR: ["target", "rel"]
    });
  }

  function renderMarkdown(block) {
    const wrapper = document.createElement("section");
    wrapper.className = "markdown-block";
    wrapper.innerHTML = sanitize(markdown.render(block.content || ""));
    enhanceTables(wrapper);
    enhanceLinks(wrapper);
    enhanceCodeBlocks(wrapper);
    return wrapper;
  }

  function enhanceTables(root) {
    root.querySelectorAll("table").forEach(function (table) {
      const wrap = document.createElement("div");
      wrap.className = "table-wrap";
      table.parentNode.insertBefore(wrap, table);
      wrap.appendChild(table);
    });
  }

  function enhanceLinks(root) {
    root.querySelectorAll("a").forEach(function (anchor) {
      const href = anchor.getAttribute("href") || "";
      anchor.setAttribute("rel", "noopener noreferrer");
      anchor.addEventListener("click", function (event) {
        event.preventDefault();
        post({ type: "linkTapped", url: href });
      });
    });
  }

  function enhanceCodeBlocks(root) {
    root.querySelectorAll("pre").forEach(function (pre) {
      const code = pre.querySelector("code");
      if (!code) return;

      const button = document.createElement("button");
      button.className = "copy-code-button";
      button.type = "button";
      button.textContent = "复制";
      button.addEventListener("click", function () {
        post({ type: "copyRequested", text: code.textContent || "" });
        button.textContent = "已复制";
        setTimeout(function () {
          button.textContent = "复制";
        }, 1200);
      });
      pre.appendChild(button);
    });
  }

  async function renderMermaid(block, index) {
    const card = document.createElement("section");
    card.className = "diagram-card";
    const stage = document.createElement("div");
    stage.className = "diagram-stage";
    card.appendChild(stage);

    try {
      const id = "mermaid-" + index + "-" + Date.now();
      const result = await window.mermaid.render(id, block.content || "");
      stage.innerHTML = result.svg;
      reportHeight();
    } catch (error) {
      return renderError("Mermaid 渲染失败", error, block.content);
    }

    return card;
  }

  function renderGraph(block) {
    try {
      const graph = JSON.parse(block.content || "{}");
      validateGraph(graph);
      return renderForceTree(graph);
    } catch (error) {
      return renderError("关系树渲染失败", error, block.content);
    }
  }

  function validateGraph(graph) {
    if (!Array.isArray(graph.nodes) || !Array.isArray(graph.edges)) {
      throw new Error("graph-json 需要包含 nodes 和 edges 数组。");
    }
    const ids = new Set();
    graph.nodes.forEach(function (node) {
      if (!node.id) {
        throw new Error("每个节点都必须包含 id。");
      }
      ids.add(String(node.id));
    });
    graph.edges.forEach(function (edge) {
      if (!ids.has(String(edge.source)) || !ids.has(String(edge.target))) {
        throw new Error("edge 引用了不存在的节点。");
      }
    });
  }

  function renderForceTree(graph) {
    const card = document.createElement("section");
    card.className = "graph-card";

    if (graph.title) {
      const title = document.createElement("h3");
      title.className = "graph-title";
      title.textContent = graph.title;
      card.appendChild(title);
    }

    const stage = document.createElement("div");
    stage.className = "graph-stage";
    card.appendChild(stage);

    const width = Math.max(320, content.clientWidth - 28);
    const height = 320;
    const nodes = graph.nodes.map(function (node) { return Object.assign({}, node); });
    const links = graph.edges.map(function (edge) { return Object.assign({}, edge); });

    const svg = d3.select(stage)
      .append("svg")
      .attr("viewBox", [0, 0, width, height].join(" "))
      .attr("width", "100%")
      .attr("height", height);

    const layer = svg.append("g");
    svg.call(d3.zoom().scaleExtent([0.65, 2.8]).on("zoom", function (event) {
      layer.attr("transform", event.transform);
    }));

    const color = d3.scaleOrdinal()
      .domain(["core", "skill", "knowledge"])
      .range(["#111827", "#0a84ff", "#34c759"]);

    const simulation = d3.forceSimulation(nodes)
      .force("link", d3.forceLink(links).id(function (d) { return d.id; }).distance(92))
      .force("charge", d3.forceManyBody().strength(-360))
      .force("center", d3.forceCenter(width / 2, height / 2))
      .force("collide", d3.forceCollide(42));

    const link = layer.append("g")
      .attr("stroke", "rgba(17,24,39,0.22)")
      .attr("stroke-width", 2)
      .selectAll("line")
      .data(links)
      .join("line");

    const node = layer.append("g")
      .selectAll("g")
      .data(nodes)
      .join("g")
      .call(d3.drag()
        .on("start", dragStarted)
        .on("drag", dragged)
        .on("end", dragEnded));

    node.append("circle")
      .attr("r", function (d) { return d.group === "core" ? 34 : 25; })
      .attr("fill", function (d) { return color(d.group || "knowledge"); })
      .attr("opacity", 0.94);

    node.append("text")
      .text(function (d) { return d.label || d.id; })
      .attr("text-anchor", "middle")
      .attr("dy", "0.35em")
      .attr("fill", "#ffffff")
      .attr("font-size", "12")
      .attr("font-weight", "700")
      .style("pointer-events", "none");

    simulation.on("tick", function () {
      link
        .attr("x1", function (d) { return d.source.x; })
        .attr("y1", function (d) { return d.source.y; })
        .attr("x2", function (d) { return d.target.x; })
        .attr("y2", function (d) { return d.target.y; });

      node.attr("transform", function (d) {
        return "translate(" + d.x + "," + d.y + ")";
      });
    });

    function dragStarted(event) {
      if (!event.active) simulation.alphaTarget(0.3).restart();
      event.subject.fx = event.subject.x;
      event.subject.fy = event.subject.y;
    }

    function dragged(event) {
      event.subject.fx = event.x;
      event.subject.fy = event.y;
    }

    function dragEnded(event) {
      if (!event.active) simulation.alphaTarget(0);
      event.subject.fx = null;
      event.subject.fy = null;
    }

    setTimeout(reportHeight, 80);
    return card;
  }

  function renderError(title, error, source) {
    const card = document.createElement("section");
    card.className = "render-error";

    const heading = document.createElement("strong");
    heading.textContent = title;
    card.appendChild(heading);

    const message = document.createElement("p");
    message.textContent = error && error.message ? error.message : String(error || "未知错误");
    card.appendChild(message);

    if (source) {
      const pre = document.createElement("pre");
      const code = document.createElement("code");
      code.textContent = source;
      pre.appendChild(code);
      card.appendChild(pre);
    }
    post({ type: "renderError", message: message.textContent });
    return card;
  }

  async function render(payload) {
    content.innerHTML = "";
    const blocks = Array.isArray(payload && payload.blocks) ? payload.blocks : [];

    for (let index = 0; index < blocks.length; index += 1) {
      const block = blocks[index];
      if (block.type === "markdown") {
        content.appendChild(renderMarkdown(block));
      } else if (block.type === "mermaid") {
        content.appendChild(await renderMermaid(block, index));
      } else if (block.type === "graph-json") {
        content.appendChild(renderGraph(block));
      }
    }

    reportHeight();
  }

  window.renderRichContent = render;
  window.addEventListener("load", reportHeight);
})();
