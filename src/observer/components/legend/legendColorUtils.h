/************************************************************************************
TerraME - a software platform for multiple scale spatially-explicit dynamic modeling.
Copyright (C) 2001-2017 INPE and TerraLAB/UFOP -- www.terrame.org

This code is part of the TerraME framework.
This framework is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

You should have received a copy of the GNU Lesser General Public
License along with this library.

The authors reassure the license terms regarding the warranties.
They specifically disclaim any warranties, including, but not limited to,
the implied warranties of merchantability and fitness for a particular purpose.
The framework provided hereunder is on an "as is" basis, and the authors have no
obligation to provide maintenance, support, updates, enhancements, or modifications.
In no event shall INPE and TerraLAB / UFOP be held liable to any party for direct,
indirect, special, incidental, or consequential damages arising out of the use
of this software and its documentation.
*************************************************************************************/

/*! \file legendColorUtils.h
    \brief This file contains functions to manipulate a structure representing a color
*/
#ifndef  __TERRALIB_INTERNAL_COLORUTILS_H
#define  __TERRALIB_INTERNAL_COLORUTILS_H

#include <iostream>
using namespace std;

#include <QString>

// #include <TeVisual.h> // issue #319
// #include <TeUtils.h>

 //! A structure for supporting a color definition
 struct TeColor
 {
	 //! Red component
	 int red_;

	 //! Green component
	 int green_;

	 //! Blue component
	 int blue_;

	 //! Color name
	 std::string name_;

	 //! Empty constructor
	 TeColor() : red_(0), green_(0), blue_(0), name_("") {}

	 //! Constructor with parameters
	 TeColor(int r, int g, int b, const std::string& name = "") : red_(r), green_(g), blue_(b), name_(name) {}

	 //! Set parameters of colors
	 void init(int r, int g, int b, const std::string& name = "") {red_ = r, green_ = g, blue_ = b; name_ = name;}

	 //! Returns TRUE if color1 is equal to color2 or FALSE if they are different.
	 bool operator==(const TeColor& color)
	 {
		 return(red_ == color.red_ && green_ == color.green_ && blue_ == color.blue_);
	 }

	 //! Assignment operator
	 TeColor& operator=(const TeColor& color)
	 {
		 if (this != &color)
		{
			 red_ = color.red_;
			 green_ = color.green_;
			 blue_ = color.blue_;
			 name_ = color.name_;
		 }
		 return *this;
	 }
 };

void rgb2Hsv(const TeColor& c, int& h, int& s, int& v); // issue #319
void RGBtoHSV(const double& r, const double& g, const double& b, double& h, double& s, double& v);
void hsv2Rgb(TeColor& c, const int& h, const int& s, const int& v); // issue #319
void HSVtoRGB(double& r, double& g, double& b, const double& h, const double& s, const double& v);

struct ColorBar {
    TeColor cor_; // issue #319
    int		h_;
    int		s_;
    int		v_;
    double	distance_;

    void color(const TeColor& c){cor_ = c; rgb2Hsv(cor_, h_, s_, v_);} // issue #319

    ColorBar& operator=(const ColorBar& cb)
    {
        cor_ = cb.cor_; // issue #319
        h_ = cb.h_;
        s_ = cb.s_;
        v_ = cb.v_;
        distance_ = cb.distance_;

        return *this;
    }

    bool operator<=(const ColorBar& cb) const
    {
        return(distance_ <= cb.distance_);
    }

    bool operator<(const ColorBar& cb) const
    {
        return(distance_ < cb.distance_);
    }

    QString toString()
    {
        QString r = QString("rgb:(%1, %2, %3); hsv:(%4, %5, %6); distance: %7;")
                .arg(cor_.red_).arg(cor_.green_).arg(cor_.blue_) // issue #319
                .arg(h_).arg(s_).arg(v_).arg(distance_);
        return r;
    }
};

#include <vector>
#include <string>
#include <map>

//! Generates a graduated color scale following a sequence of basic colors
/*!
        The possible basic colors are "RED", "GREEN", "BLUE", "YELLOW", "CYAN", "MAGENTA", "GRAY" and  "BLACK"
        \param ramps	vector with the sequence color ramps used to build the scale
        \param nc		desired number of colors on the scale
        \param colors	resulting color scale
        \returns true if color scale was successfully generated and false otherwise
*/
bool getColors(std::vector<std::string>& ramps, int nc, std::vector<TeColor>& colors); // issue #319
vector<TeColor> getColors(TeColor cfrom, TeColor cto, int nc); // issue #319
vector<TeColor> getColors(vector<ColorBar>& iVec, int ncores); // issue #319
string getColors(vector<ColorBar>& aVec, vector<ColorBar>& bVec, int groupingMode);
void generateColorBarMap(vector<ColorBar>& inputColorVec, int ncores, map<int, vector<TeColor> >& colorMap); // issue #319
vector<ColorBar> getColorBarVector(string& scores, const bool& first);
//unsigned int  TeReadColorRampTextFile(const string& fileName, map<string,string>& colorRamps);

/// <TeDefines>
//! A default name length
const int	TeNAME_LENGTH = 2000;			//!< A default name length

/// <TeUtils>
//! Rounds a double to int
inline int TeRound(double val)
{
	if (val >= 0)
		return(int)(val + .5);
	else
		return(int)(val - .5);
}

inline string
Te2String(const int value)
{
	char name[TeNAME_LENGTH];
	sprintf(name, "%d", value);
	return name;
}

inline string
Te2String(const unsigned int value)
{
	char name[TeNAME_LENGTH];
	sprintf(name, "%u", value);
	return name;
}

inline string
Te2String(const long value)
{
	char name[TeNAME_LENGTH];
	sprintf(name, "%ld", value);
	return name;
}

inline string
Te2String(const long long int value)
{
	char name[TeNAME_LENGTH];
	sprintf(name, "%lld", value);
	return name;
}

inline string
Te2String(const unsigned long value)
{
	char name[TeNAME_LENGTH];
	sprintf(name, "%lu", value);
	return name;
}

inline string
Te2String(const double value, int precision)
{
	char name[TeNAME_LENGTH];
	sprintf(name, "%.*f", precision, value);

	std::string strOut(name);
	size_t found = strOut.find(',');
	if (found != std::string::npos)
	{
		strOut[(int)found] = '.';
	}

	return strOut;
}


inline string
Te2String(const double value)
{
	char name[TeNAME_LENGTH];
	sprintf(name, "%e", value);

	std::string strOut(name);
	size_t found = strOut.find(',');
	if (found != std::string::npos)
	{
		strOut[(int)found] = '.';
	}

	return strOut;
}


#endif

