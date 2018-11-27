# Cervix93 Cytology Dataset

The dataset has 93 image stacks and their corresponding Extended Depth of Field (EDF) image acquired from cases with grades Nagative, LSIL or HSIL (The Bethesda System):
* Negative: 16
* LSIL: 46
* HSIL: 31

The ground truth includes the grade labels for each frame and manually marked points inside cervical cells in each frame. The are in total 2705 manually marked points inside all frames:
* Negative: 238
* LSIL: 1536
* HSIL: 931

### Training and Test sets

The dataset is divided into Training (set 0) and Test (set 1). The distriution of frames and marked nuclei in each frame is as follows.

#### Trainig
* Negative: 12 frames, 179 nuclei
* LSIL: 34 frames, 1125 nuclei
* HSIL: 23 frames, 679 nuclei

#### Test
* Negative: 4 frames, 59 nuclei
* LSIL: 12 frames, 411 nuclei
* HSIL: 8 frames, 252 nuclei

### Codes

The codes folder include the detection evaluation script (MATLAB), a baseline segmentation method and a test script evaluating the baseline segmentation method on the test dataset.

### Reference

The paper explaining the dataset and the methods in more details can be downloaded at the following link: https://arxiv.org/abs/1811.09651