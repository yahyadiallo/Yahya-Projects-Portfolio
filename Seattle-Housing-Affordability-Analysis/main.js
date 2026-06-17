const rentFile = "RentTypology.csv";
const incomeFile = "household-income.csv";

const width = 1000;
const height = 580;

const margin = {
  top: 90,
  right: 220,
  bottom: 80,
  left: 90
};

const svg = d3.select("#chart")
  .append("svg")
  .attr("width", width)
  .attr("height", height);

Promise.all([
  d3.csv(rentFile),
  d3.csv(incomeFile)
]).then(function(files) {

  const rentRaw = files[0];
  const incomeRaw = files[1];

  rentRaw.forEach(function(d) {
    d.Year = +d.Year;
    d.Rent = +d["Tract Median Apartment Contract Rent per Unit"];
  });

  incomeRaw.forEach(function(d) {
    d.Year = +d.Year;
    d.Income = +d["Median Household Income"].replaceAll(",", "");
  });

  const rentByYear = d3.rollups(
    rentRaw.filter(d => !isNaN(d.Rent)),
    v => d3.mean(v, d => d.Rent),
    d => d.Year
  );

  let rentData = rentByYear.map(function(d) {
    return {
      Year: d[0],
      Value: d[1]
    };
  });

  let incomeData = incomeRaw.map(function(d) {
    return {
      Year: d.Year,
      Value: d.Income
    };
  });

  rentData = rentData
    .filter(d => d.Year >= 2018 && d.Year <= 2023)
    .sort((a, b) => a.Year - b.Year);

  incomeData = incomeData
    .filter(d => d.Year >= 2018 && d.Year <= 2023)
    .sort((a, b) => a.Year - b.Year);

  const baseRent = rentData[0].Value;
  const baseIncome = incomeData[0].Value;

  rentData.forEach(function(d) {
    d.PercentChange = ((d.Value - baseRent) / baseRent) * 100;
  });

  incomeData.forEach(function(d) {
    d.PercentChange = ((d.Value - baseIncome) / baseIncome) * 100;
  });

  const allData = rentData.concat(incomeData);

  const xScale = d3.scaleLinear()
    .domain([2018, 2023])
    .range([margin.left, width - margin.right]);

  const yScale = d3.scaleLinear()
    .domain([
      d3.min(allData, d => d.PercentChange) - 5,
      d3.max(allData, d => d.PercentChange) + 5
    ])
    .range([height - margin.bottom, margin.top]);

  // Background sections
  svg.append("rect")
    .attr("x", xScale(2018))
    .attr("y", margin.top)
    .attr("width", xScale(2020) - xScale(2018))
    .attr("height", height - margin.top - margin.bottom)
    .attr("fill", "#eeeeee");

  svg.append("rect")
    .attr("x", xScale(2020))
    .attr("y", margin.top)
    .attr("width", xScale(2022) - xScale(2020))
    .attr("height", height - margin.top - margin.bottom)
    .attr("fill", "#dddddd");

  svg.append("rect")
    .attr("x", xScale(2022))
    .attr("y", margin.top)
    .attr("width", xScale(2023) - xScale(2022))
    .attr("height", height - margin.top - margin.bottom)
    .attr("fill", "#f7f7f7");

  // Zero line
  svg.append("line")
    .attr("x1", margin.left)
    .attr("x2", width - margin.right)
    .attr("y1", yScale(0))
    .attr("y2", yScale(0))
    .attr("stroke", "#777")
    .attr("stroke-width", 1);

  // X axis
  svg.append("g")
    .attr("transform", `translate(0, ${height - margin.bottom})`)
    .call(
      d3.axisBottom(xScale)
        .tickValues([2018, 2019, 2020, 2021, 2022, 2023])
        .tickFormat(d3.format("d"))
    );

  // Y axis
  svg.append("g")
    .attr("transform", `translate(${margin.left}, 0)`)
    .call(d3.axisLeft(yScale).tickFormat(d => d + "%"));

  const line = d3.line()
    .x(d => xScale(d.Year))
    .y(d => yScale(d.PercentChange));

  // Rent line
  svg.append("path")
    .datum(rentData)
    .attr("fill", "none")
    .attr("stroke", "#e63946")
    .attr("stroke-width", 3)
    .attr("d", line);

  // Income line
  svg.append("path")
    .datum(incomeData)
    .attr("fill", "none")
    .attr("stroke", "#1d4ed8")
    .attr("stroke-width", 3)
    .attr("d", line);

  // Rent dots
  svg.selectAll(".rent-dot")
    .data(rentData)
    .enter()
    .append("circle")
    .attr("cx", d => xScale(d.Year))
    .attr("cy", d => yScale(d.PercentChange))
    .attr("r", 4)
    .attr("fill", "#e63946");

  // Income dots
  svg.selectAll(".income-dot")
    .data(incomeData)
    .enter()
    .append("circle")
    .attr("cx", d => xScale(d.Year))
    .attr("cy", d => yScale(d.PercentChange))
    .attr("r", 4)
    .attr("fill", "#1d4ed8");

  // COVID divider line
  svg.append("line")
    .attr("x1", xScale(2020))
    .attr("x2", xScale(2020))
    .attr("y1", margin.top)
    .attr("y2", height - margin.bottom)
    .attr("stroke", "black")
    .attr("stroke-dasharray", "5,5");

  svg.append("text")
    .attr("x", xScale(2020) + 8)
    .attr("y", margin.top + 20)
    .style("font-size", "12px")
    .text("COVID begins");

  // Story labels
  svg.append("text")
    .attr("x", xScale(2019))
    .attr("y", 60)
    .attr("text-anchor", "middle")
    .attr("class", "story-label")
    .text("Before COVID");

  svg.append("text")
    .attr("x", xScale(2021))
    .attr("y", 60)
    .attr("text-anchor", "middle")
    .attr("class", "story-label")
    .text("During COVID");

  svg.append("text")
    .attr("x", xScale(2022.5))
    .attr("y", 60)
    .attr("text-anchor", "middle")
    .attr("class", "story-label")
    .text("After COVID");

  // Chart title
  svg.append("text")
    .attr("x", width / 2)
    .attr("y", 32)
    .attr("text-anchor", "middle")
    .style("font-size", "21px")
    .style("font-weight", "bold")
    .style("fill", "#17176f")
    .text("Seattle Rent Growth vs Household Income Growth");

  // Axis labels
  svg.append("text")
    .attr("x", width / 2)
    .attr("y", height - 28)
    .attr("text-anchor", "middle")
    .attr("class", "axis-label")
    .text("Year");

  svg.append("text")
    .attr("x", -height / 2)
    .attr("y", 28)
    .attr("transform", "rotate(-90)")
    .attr("text-anchor", "middle")
    .attr("class", "axis-label")
    .text("Change Since 2018 (%)");

  // Legend
  svg.append("circle")
    .attr("cx", width - 190)
    .attr("cy", 105)
    .attr("r", 5)
    .attr("fill", "#e63946");

  svg.append("text")
    .attr("x", width - 175)
    .attr("y", 110)
    .attr("class", "legend-text")
    .text("Rent Growth");

  svg.append("circle")
    .attr("cx", width - 190)
    .attr("cy", 132)
    .attr("r", 5)
    .attr("fill", "#1d4ed8");

  svg.append("text")
    .attr("x", width - 175)
    .attr("y", 137)
    .attr("class", "legend-text")
    .text("Income Growth");

  // Last point labels
  const lastRent = rentData[rentData.length - 1];
  const lastIncome = incomeData[incomeData.length - 1];

  svg.append("text")
    .attr("x", xScale(lastRent.Year) + 10)
    .attr("y", yScale(lastRent.PercentChange) + 5)
    .style("font-size", "12px")
    .style("fill", "#e63946")
    .style("font-weight", "bold")
    .text("Rent +" + lastRent.PercentChange.toFixed(1) + "%");

  svg.append("text")
    .attr("x", xScale(lastIncome.Year) + 10)
    .attr("y", yScale(lastIncome.PercentChange) + 5)
    .style("font-size", "12px")
    .style("fill", "#1d4ed8")
    .style("font-weight", "bold")
    .text("Income +" + lastIncome.PercentChange.toFixed(1) + "%");

});