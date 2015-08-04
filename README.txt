How to use the algorithms
-------------------------

Each algorithm is run from the folder with its name. In each folder, there is a file with [algorithm]_gui.m as the name, which can be run to show the algorithm GUI. For example, simulated annealing (SA) is named 'SA_gui.m'. The GUI has a settings panel on the left side, a plot in the middle, and a results panel on the right. 

The settings for each algorithm can be run from the settings panel. When you have the desired settings, click the button at the bottom of the settings panel, which is named the algorithm which is required. The plot will then show the results in real time. Once the algorithm has finished, the results will be shown in the panel on the right.

Note that the settings for each algorithm has set maximum and minimum values, either for the optimality of the code, or for timing issues for large populations or generation numbers.

How to view the code base
-------------------------
For each algorithm, the main function is named as it's name - for example, the genetic algorithm is named 'GA.m' - this is the main code base. In addition, the file 'evaluateSoln.m' shows the way the solution cost is evaluated. The input files with the store distances and inventories are called REAL_distances and REAL_inventory respectively. The other files in the folder are either alternate input files or helper functions.