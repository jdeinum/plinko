# Plinko

This Plinko game was created to analyze the distributions of the landings and the most common 
paths using Python and Neo4j. The code is feature complete but that's where it ends...

I am running this on Arch Linux, and assume jupyterlab, python3, and docker are installed.


# Running
To run the plinko simulator, run `love .` after installing the Love engine for lua.
The log file will be present in `result.dat`. 


# Analyzing using Pandas
To analyze the distribution of landings relative to start points, use the provided 
jupyter notebook by creating a virtual environment and installing the dependencies:

```bash
# create the env
python3 -m venv env

# source the new env
source ./env/bin/activate

# install dependencies
pip3 install -r requirements.txt

# open jupyterlab in the current directory
jupyter-lab .
```

Once you're here, you can run all of the cells to see a histogram of the landings, as well
as a scatterplot with startX as the x axis, and what bin it landed in on the y axis.

# Analyzing using Neo4j
To analyze the paths taken by the plinko ball, we can load the data into a Neo4j DB and query 
it using cipher. To start the Neo4j database, change directory to `./neo4j` and run `docker compose up -d`

Now you should be able to visit `http://localhost:7474` and access the Neo4j database. When the data
is loaded in, each Pin and Bin are inserted with properties outlining its location. A relationship is 
made from pin A to pin B when the ball hits pin B directly after is hits pin A.

By looking at these paths, we can determine centrality measures like which pin is part of the most paths,
which pins, which pins act as articulation points, and more. 

The same analysis can be done in python3, but it's less fun and more awkward, so I chose to use 
cipher instead :)

The queries to answer questions are located inside the `local queries` section inside the container.
