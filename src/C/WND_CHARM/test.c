


#include "TrainingSet.h"

#include <stdio.h>

int main()
{   TrainingSet *ts,*train,*test;
     double res;
     ts=new TrainingSet(1000,15);
     train=new TrainingSet(1000,15);
     test=new TrainingSet(1000,15);
     ts->LoadFromDir("../data/yale");
     ts->SaveToFile("../data/yale/yale.txt");
     randomize();
     ts->split(0.2,train,test);
     train->normalize();
     train->SetFisherScores(0.1);
     res=train->Test(test,0);
     printf("res=%f\n",res);
     
     delete ts;
     delete train;
     delete test;
     return(1);
}