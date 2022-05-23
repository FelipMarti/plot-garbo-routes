from gps_class import GPSVis

import sys, getopt, os


def main(argv):
    inputfile = ''
    outputfile = ''
    inputfolder = ''
    graph_title ='' 
    try:
        opts, args = getopt.getopt(argv,"hi:o:f:",["ifile=","ofile=","ifolder="])
    except getopt.GetoptError:
        print ('test.py -i <inputfile> -o <outputfile>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print ('test.py -i <inputfile> -o <outputfile>')
            sys.exit()
        elif opt in ("-i", "--ifile"):
            inputfile = arg
        elif opt in ("-o", "--ofile"):
            outputfile = arg
        elif opt in ("-f", "--ifolder"):
            inputfolder = arg
    if not inputfile and not inputfolder:
        print ('test.py -i <inputfile> -o <outputfile>')
        print ('or')
        print ('test.py -f <inputfolder> -o <outputfile>')
        sys.exit(2)

    if inputfile:
        print('Input file is ' + inputfile)
        graph_title = os.path.basename(inputfile) 
        graph_title = os.path.splitext(graph_title)[0]
    elif inputfolder:
        graph_title = os.path.basename(inputfolder)
        print('Input folder is ' + inputfolder)

    if not outputfile and inputfile:
        outputfile=os.path.splitext(inputfile)[0]
        outputfile=outputfile + '.eps'
    elif not outputfile and inputfolder:
        outputfile=os.path.abspath(inputfolder) + '.eps'
    print('Output file is ' + outputfile)

    script_path = os.path.dirname(sys.argv[0])
    map_path = script_path + '/' + 'map.png'
    print(map_path)
    vis = GPSVis(title=graph_title,
            map_path=map_path,  # Path to map downloaded from the OSM.
            points=(-37.68, 144.75, -37.825, 144.89)) # Two coordinates of the map (upper left, lower right)

    if inputfile:
        vis.create_image(data_path=inputfile, color='blue', width=3)  # Set the color and the width of the GNSS tracks.

    elif inputfolder:
        colours = ['blue', 'red', 'orange', 'darkgreen' ,'magenta', 'purple', 'coral', 'cornflowerblue', 'limegreen', 'darkorchid', 'gold', 'steelblue', 'yellowgreen', 'chocolate', 'teal']
        rotate_colour = 0

        file_list = os.listdir(inputfolder)
        for filename in sorted(file_list):
            inputfile = inputfolder + '/' + filename

            if os.path.splitext(inputfile)[1] == '.log':
                print (inputfile)
                vis.create_image(data_path=inputfile, color=(colours[rotate_colour]), width=3)  # Set the color and the width of the GNSS tracks.
                rotate_colour += 1
            else:
                print ('Ignoring file with wrong extension:' + inputfile)
            

    vis.plot_map(output='save', save_as=outputfile)

    print()



if __name__ == "__main__":
    main(sys.argv[1:])

