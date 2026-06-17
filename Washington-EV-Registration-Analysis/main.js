const width = 780;
const height = 520;

const margin = {
  top: 90,
  right: 80,
  bottom: 90,
  left: 80
};

const svg = d3.select("#chart")
  .append("svg")
  .attr("width", width)
  .attr("height", height);

d3.csv("EV-Data.csv").then(function(data) {

  // Keep rows that have both city and make
  const cleanedData = data.filter(function(d) {
    return d.City && d.City.trim() !== "" &&
           d.Make && d.Make.trim() !== "";
  });

  // Find top 8 cities
  const cityCounts = d3.rollups(
    cleanedData,
    function(v) { return v.length; },
    function(d) { return d.City; }
  );

  cityCounts.sort(function(a, b) {
    return b[1] - a[1];
  });

  const topCities = cityCounts.slice(0, 8).map(function(d) {
    return d[0];
  });

  // Find top 8 car makes
  const makeCounts = d3.rollups(
    cleanedData,
    function(v) { return v.length; },
    function(d) { return d.Make; }
  );

  makeCounts.sort(function(a, b) {
    return b[1] - a[1];
  });

  const topMakes = makeCounts.slice(0, 8).map(function(d) {
    return d[0];
  });

  // Keep only top cities and top makes
  const filteredData = cleanedData.filter(function(d) {
    return topCities.includes(d.City) && topMakes.includes(d.Make);
  });

  // Count each city + make combo
  const heatmapData = d3.rollups(
    filteredData,
    function(v) { return v.length; },
    function(d) { return d.City; },
    function(d) { return d.Make; }
  );

  let chartData = [];

  heatmapData.forEach(function(cityGroup) {
    cityGroup[1].forEach(function(makeGroup) {
      chartData.push({
        city: cityGroup[0],
        make: makeGroup[0],
        count: makeGroup[1]
      });
    });
  });

  const xScale = d3.scaleBand()
    .domain(topMakes)
    .range([margin.left, width - margin.right])
    .padding(0.05);

  const yScale = d3.scaleBand()
    .domain(topCities)
    .range([margin.top, height - margin.bottom])
    .padding(0.05);

  const colorScale = d3.scaleSequential()
    .domain([0, d3.max(chartData, function(d) {
      return d.count;
    })])
    .interpolator(d3.interpolateBlues);

  svg.append("text")
    .attr("x", margin.left)
    .attr("y", 40)
    .attr("font-size", "27px")
    .attr("font-weight", "bold")
    .text("Tesla Dominates EV Registrations In Washington’s Top Cities");

  svg.append("text")
    .attr("x", margin.left)
    .attr("y", 68)
    .attr("class", "note")
    .text("Darker squares show higher counts. The pattern shows which brands are most common in each city.");

  svg.selectAll(".heat-box")
    .data(chartData)
    .enter()
    .append("rect")
    .attr("class", "heat-box")
    .attr("x", function(d) {
      return xScale(d.make);
    })
    .attr("y", function(d) {
      return yScale(d.city);
    })
    .attr("width", xScale.bandwidth())
    .attr("height", yScale.bandwidth())
    .attr("fill", function(d) {
      return colorScale(d.count);
    });

  svg.selectAll(".heat-label")
    .data(chartData)
    .enter()
    .append("text")
    .attr("class", "heat-label")
    .attr("x", function(d) {
      return xScale(d.make) + xScale.bandwidth() / 2;
    })
    .attr("y", function(d) {
      return yScale(d.city) + yScale.bandwidth() / 2 + 4;
    })
    .attr("text-anchor", "middle")
    .text(function(d) {
      return d.count;
    });

  svg.append("g")
    .attr("class", "axis")
    .attr("transform", "translate(0," + margin.top + ")")
    .call(d3.axisTop(xScale));

  svg.append("g")
    .attr("class", "axis")
    .attr("transform", "translate(" + margin.left + ",0)")
    .call(d3.axisLeft(yScale));

});