#!/usr/bin/env python3
''' Generate data to feed the test bench for axi_freq_selector
'''
import numpy as np

LENGTH = 2**16
AMP_MAX = (2**14)/2 - 1
FREQS = [20000, 20300, 21000, -23000]
RANDOM_SEED = 0


def wave_gen(freqs, phases):
    ''' Generate a wave in the complex plane
    '''
    _x = np.arange(LENGTH)
    wave_i = sum([np.cos(2*np.pi*_x*f/LENGTH + p) for f, p in zip(freqs, phases)])
    wave_q = sum([np.sin(2*np.pi*_x*f/LENGTH + p) for f, p in zip(freqs, phases)])
    factor = AMP_MAX/min(np.abs(wave_i).max(), np.abs(wave_q).max())
    wave_i = (wave_i * factor).round()
    wave_q = (wave_q * factor).round()
    return wave_i + 1j*wave_q


def fft_quad(wave):
    ''' Simulate the operation of "FFT quad"
    '''
    ffts = np.array([np.fft.fft(wave[i::4]) for i in range(4)])
    phases = np.array([np.exp(-2*i*np.pi*1j*np.arange(len(wave)/4)/len(wave)) for i in range(4)])
    fftp = phases * ffts
    factors = np.array([[np.exp(-2*np.pi*1j*i*k/4) for k in range(4)] for i in range(4)])
    return np.dot(factors, fftp)


def freq2ind(freq):
    ''' Calculate indices in fft_quad output from the given frequency
    '''
    freq = (freq + LENGTH)%LENGTH
    res = freq % (LENGTH/4)
    fft_ind = (freq - res)/(LENGTH/4)
    return int(fft_ind), int(res)


def reverse(val):
    ''' Reverse bits. Assuming the input has 14 bits
    '''
    return int(f'{val:014b}'[::-1], 2)


def index_plan(indices):
    ''' Integrate a list of indices to a dictionary that contains
        lists of "k"s (fft index) in bit-reversed order
    '''
    d_ret = {}
    for _g in range(4):
        d_ret[_g] = []

    for _g, _i in indices:
        d_ret[_g].append(_i)
    
    for _g, _list in d_ret.items():
        d_ret[_g] = [reverse(val) for val in sorted([reverse(ind) for ind in _list])]

    return d_ret


def iq2bin64(iq):
    ''' Convert IQ data to 64 bit binary representation
    '''
    r_b = int(iq.real).to_bytes(4, 'big', signed=True)
    r_str = ''.join([f'{_b:08b}' for _b in r_b])
    i_b = int(iq.imag).to_bytes(4, 'big', signed=True)
    i_str = ''.join([f'{_b:08b}' for _b in i_b])
    return i_str + r_str


def main():
    ''' Main function'''
    # Data preparation
    rs = np.random.RandomState(seed=RANDOM_SEED)
    phases = rs.uniform(0, 2*np.pi, size=len(FREQS))
    wave = wave_gen(FREQS, phases)
    result_fq = fft_quad(wave)

    # Index plan
    plan = index_plan([freq2ind(_f) for _f in FREQS])
    k_list = [reverse(k_raw) for k_raw in np.arange(int(LENGTH/4))]

    # Output
    for _ch in range(4):
        with open(f'plan_{_ch}.bin', 'w') as file_plan:
            for _k in plan[_ch]:
                file_plan.write(f'{_k:014b}\n')

        with open(f'k_{_ch}.bin', 'w') as file_k:
            for _k in k_list:
                file_k.write(f'{_k:014b}\n')

        with open(f'data_{_ch}.bin', 'w') as file_data:
            for val in result_fq[_ch][k_list]:
                file_data.write(iq2bin64(val) + '\n')


if __name__ == '__main__':
    main()
