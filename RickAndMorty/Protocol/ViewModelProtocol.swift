//
//  ViewModelProtocol.swift
//  RickAndMorty
//
//  Created by Moon Jongseek on 2022/07/04.
//

import Foundation

protocol ViewModelProtocol {
    func requestTotalCount() -> ()
    func requestInfo(ID: Int) -> ()
}
