
fetch('./data.json')
    .then(res => res.json())
    .then(data => {
        let total = 0;

        const allData = Object.keys(data)
            .map(key => {
                total += data[key];
                return { name: key, count: data[key] };
            })
            .sort((a, b) => b.count - a.count);

        const labels = [];
        const dataset = [];

        allData.forEach(item => {
            labels.push(item.name);
            const itemFrequency = (item.count / total) * 100;
            dataset.push(itemFrequency);
        })

        drawChart(labels, dataset);
    });

function drawChart(labels, dataset) {
    const chartCtx = document.getElementById('chart').getContext('2d');

    const chartOptions = {
        type: 'line',
        data: {
            labels,
            datasets: [{
                label: 'Item frequency',
                backgroundColor: '#3F51B5',
                data: dataset
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            legend: {
                display: false
            },
            animation: {
                duration: 0
            },
            hover: {
                animationDuration: 0
            },
            responsiveAnimationDuration: 0,
            elements: {
                line: {
                    tension: 0 // disables bezier curves
                }
            },
            showLines: false,
            ticks: {
                sampleSize: 1,
                minRotation: 0,
                maxRotation: 0
            }
        }
    };

    const myChart = new Chart(chartCtx, chartOptions);

    (function fitChart() {
        const xAxisLabelMinWidth = 10;

        const chartCanvas = document.getElementById('chart');
        const maxWidth = chartCanvas.parentElement.parentElement.clientWidth;
        const width = Math.max(myChart.data.labels.length * xAxisLabelMinWidth, maxWidth);

        chartCanvas.parentElement.style.width = width + 'px';
    })();
}